<template>
  <v-card elevation-1 class="my-2">
    <v-toolbar dense color="grey lighten-2" flat height="32" class="ice-filter-toolbar">
      <strong>{{ variable.label }} <span v-if="variable.units">({{variable.units}})</span></strong>
      <v-tooltip right max-width="600">
        <template v-slot:activator="{ on }">
          <v-icon class="pl-2" v-on="on" small>mdi-information</v-icon>
        </template>
        {{ variable.description }}
      </v-tooltip>
      <v-spacer></v-spacer>
      <v-btn small icon @click="hide = !hide">
        <v-icon v-if="!hide">mdi-menu-up</v-icon>
        <v-icon v-else>mdi-menu-down</v-icon>
      </v-btn>
      <v-btn small icon @click="close"><v-icon small>mdi-close</v-icon></v-btn>
    </v-toolbar>
    <v-card-text v-if="!hide" class="py-0 px-2 caption">
      <div :class="{ 'float-right': true, 'mr-6': filterLabel === 'None', 'mr-0': filterLabel !== 'None' }" style="height:20px">
        Filter: {{ filterLabel }}
        <v-tooltip right open-delay="300">
          <template v-slot:activator="{ on }">
            <v-btn icon x-small v-on="on" v-show="!!filter" @click="resetFilter">
              <v-icon x-small>mdi-close-circle</v-icon>
            </v-btn>
          </template>
          <span>Clear Filter</span>
        </v-tooltip>
      </div>
    </v-card-text>
    <div class="ice-filter-chart" v-show="!hide"></div>
  </v-card>
</template>

<script>
import dc from 'dc'
import * as d3 from 'd3'

import evt from '@/lib/events'
import variableMixin from '@/mixins/variable'
import { getCrossfilter } from '@/lib/crossfilter'
import { mapGetters } from 'vuex'

export default {
  name: 'IceFilter',
  mixins: [variableMixin],
  props: {
    variable: {
      type: Object,
      required: false
    }
  },
  data () {
    return {
      filter: null,
      hide: false
    }
  },
  computed: {
    ...mapGetters(['theme']),
    yLabel () {
      return this.theme.id.startsWith('gage-') ? '# Gages' : '# HUC12s'
    },
    filterLabel () {
      if (this.variable.type === 'num') {
        if (!this.filter) return 'None'
        const values = this.filter.map(this.inverseTransform).map(this.valueFormatter)
        if (this.variable.scale.clipped[0] && values[0] <= this.variable.scale.domain[0]) {
          values[0] = `<=${values[0]}`
        }
        if (this.variable.scale.clipped[1] && values[1] >= this.variable.scale.domain[1]) {
          values[1] = `${values[1]}+`
        }
        return `${values[0]} to ${values[1]}`
      } else {
        if (!this.filter || this.filter.length === 0) return 'None'
        return this.filter.length > 1 ? `${this.filter.length} values` : `${this.filter.length} value`
      }
    }
  },
  mounted () {
    const width = 460
    const el = this.$el.getElementsByClassName('ice-filter-chart').item(0)
    const xf = getCrossfilter()

    if (this.variable.type === 'num') {
      const dim = xf.dimension(d => {
        let value = d[this.variable.id]
        if (value == null) {
          return this.transform(value)
        } else if (value > this.variable.scale.domain[1]) {
          value = this.variable.scale.domain[1]
        } else if (value < this.variable.scale.domain[0]) {
          value = this.variable.scale.domain[0]
        }
        return this.transform(value)
      })

      const l = this.transform(this.variable.scale.domain[0])
      const u = this.transform(this.variable.scale.domain[1])
      const n = 30
      const interval = (u - l) / n
      const group = dim.group(d => l + Math.floor(n * (d - l) / (u - l)) * interval).reduceCount()
      const margins = { top: 5, right: 40, bottom: 20, left: 40 }
      const domain = this.variable.scale.domain.slice()
      domain[1] *= 1.00001

      this.chart = dc.barChart(el)
        .width(width)
        .height(120)
        .margins(margins)
        .dimension(dim)
        .group(group)
        .elasticY(true)
        .transitionDelay(0)
        .colors('#5095c3')
        .x(d3.scaleLinear().domain(domain.map(this.transform)))
        .yAxisLabel(this.yLabel, 24)
        .on('filtered', () => {
          const filter = this.chart.dimension().currentFilter()
          if (filter) {
            this.filter = [filter[0], filter[1]]
          } else {
            this.filter = undefined
          }
          evt.$emit('xf:filter')
          evt.$emit('map:render')
        })
        .on('renderlet', () => {
          if (this.variable.scale.clipped[0]) {
            const tick = this.chart.select('.x.axis g.tick text')
            if (+tick.text() === this.variable.scale.domain[0]) {
              tick.text(`<= ${tick.text()}`)
            }
          }
          if (this.variable.scale.clipped[1]) {
            const ticks = this.chart.selectAll('.x.axis g.tick text')
              .filter(function () {
                return d3.select(this).text() !== ''
              })
            const tick = d3.select(ticks.nodes()[ticks.size() - 1])
            if (+tick.text() === this.variable.scale.domain[1]) {
              tick.text(`${tick.text()}+`)
            }
          }
        })

      this.chart.xUnits(() => n)
      this.chart.xAxis()
        .ticks(5)
        .tickFormat(d => this.filterFormatter(this.inverseTransform(d)))

      this.chart.yAxis().ticks(4)
    } else {
      const margins = { top: 0, right: 40, bottom: 35, left: 15 }
      const dim = xf.dimension(d => d[this.variable.id])
      const group = dim.group().reduceCount()
      const count = this.variable.scale.domain.length
      // window.xf = xf
      // window.dim = dim
      // window.group = group
      // console.log(count)
      const gap = 5
      const barHeight = 20
      const height = margins.top + margins.bottom + barHeight * count + gap * (count + 1)

      this.chart = dc.rowChart(el)
        .width(width)
        .height(height)
        .margins(margins)
        .dimension(dim)
        .group(group)
        .elasticX(true)
        .transitionDelay(0)
        .transitionDuration(0)
        .gap(gap)
        .colors('#5095c3')
        .ordering(d => this.variable.scale.domain.findIndex(v => v.id === d.key))
        .label(d => d.key)
        // .xAxisLabel(this.yLabel, 24)
        .on('filtered', () => {
          const filter = this.chart.filters()
          if (filter && filter.length > 0) {
            this.filter = filter
          } else {
            this.filter = undefined
          }
          evt.$emit('xf:filter')
          evt.$emit('map:render')
        })
        .on('renderlet', (chart) => {
          chart.select('.axis').selectAll('g.tick:not(:first-of-type) line.grid-line').style('display', 'none')
          const label = chart.select('.axis').select('text.x-axis-label')
          if (label.size() === 0) {
            chart.select('.axis')
              .append('text')
              .attr('class', 'x-axis-label')
              .attr('text-anchor', 'middle')
              .attr('x', chart.width() * 0.44)
              .attr('y', 30)
              .text(this.yLabel)
          }
        })
    }

    this.chart.render()

    evt.$on('filter:render', this.render)
  },
  beforeDestroy () {
    if (this.chart) {
      this.chart.dimension().dispose()
      dc.chartRegistry.deregister(this.chart)
      dc.renderAll()
    }
    evt.$off('filter:render', this.render)
    evt.$emit('xf:filter')
    evt.$emit('map:render')
  },
  methods: {
    render () {
      this.chart && this.chart.render()
    },
    resetFilter () {
      this.chart && this.chart.filterAll()
      dc.redrawAll()
    },
    close () {
      this.$emit('close')
    }
  }
}
</script>

<style>
.dc-chart {
  float: none !important;
}
.dc-chart text.y-axis-label.y-label {
  fill: hsl(0, 0%, 20%);
  font-size: 0.8em;
  font-family: sans-serif;
}
.dc-chart g.row rect {
  fill-opacity: 1;
}
.dc-chart g.row text {
  fill: hsl(0, 0%, 10%);
  font-weight: 400;
}
.dc-chart text.x-axis-label {
  fill: hsl(0, 0%, 20%);
  font-size: 1em;
  font-family: sans-serif;
}
</style>
