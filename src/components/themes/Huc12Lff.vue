<template>
  <ice-feature-container v-if="selected" @close="$emit('close')" :loading="loading" :error="error">
    <template v-slot:title>
      Selected HUC12: {{selected.id}}
    </template>

    <div v-if="!loading && !error && dataset">
      <ice-huc12-properties-box :properties="dataset.properties"></ice-huc12-properties-box>

      <ice-feature-box>
        <template v-slot:title>Low Flow Statistics</template>
        <highcharts class="chart" :options="charts.stats"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Spatial Bias Correction</template>
        <highcharts class="chart" :options="charts.bias"></highcharts>
      </ice-feature-box>
    </div>
  </ice-feature-container>
</template>

<script>
import highcharts from 'highcharts'

import themeSelect from '@/mixins/themeSelect'

const variables = []
for (const y of ['1', '7', '30']) {
  for (const x of [2, 5, 10, 20]) {
    variables.push({
      label: `${y}Q${x}`,
      stat: `huc_${y}Day${x}yr_Est_corrII`,
      bias: `finalBias_${y}Q${x}`
    })
  }
}

export default {
  name: 'Huc12Lff',
  mixins: [themeSelect],
  data () {
    return {
      charts: {
        bias: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            type: 'line'
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 2,
            valueSuffix: ' log10[cms]',
            shared: false,
            headerFormat: '<span>Statistic: <b>{point.key}</b></span><br/>',
            pointFormat: '<span style="color:{point.color}">\u25CF</span> Bias Correction: <b>{point.y}</b><br/>'
          },
          xAxis: {
            categories: variables.map(v => v.label),
            title: {
              text: 'Low Flow Statistic'
            }
          },
          yAxis: {
            type: 'linear',
            title: {
              text: 'log10[Streamflow (cms)]'
            }
          },
          legend: {
            enabled: false
          },
          series: []
        },
        stats: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            type: 'line'
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 2,
            shared: false,
            headerFormat: '<span>Statistic: <b>{point.key}</b></span><br/>',
            pointFormat: '<span style="color:{point.color}">\u25CF</span> Estimate: <b>{point.y}</b><br/>',
            valueSuffix: ' log10[cms]'
          },
          xAxis: {
            categories: variables.map(v => v.label),
            title: {
              text: 'Low Flow Statistic'
            }
          },
          yAxis: {
            type: 'linear',
            title: {
              text: 'log10[Streamflow (cms)]'
            }
          },
          legend: {
            enabled: false
          },
          series: []
        }
      }
    }
  },
  methods: {
    updateCharts () {
      this.clearCharts()
      console.log(this.values)
      const value = this.values[0]
      this.charts.bias.series = [
        {
          data: [...variables.slice(0, 4).map(c => value[c.bias]), null, null, null, null, null, null, null, null]
        },
        {
          data: [null, null, null, null, ...variables.slice(4, 8).map(c => value[c.bias]), null, null, null, null]
        },
        {
          data: [null, null, null, null, null, null, null, null, ...variables.slice(8, 12).map(c => value[c.bias])]
        }
      ]
      this.charts.stats.series = [
        {
          data: [...variables.slice(0, 4).map(c => value[c.stat]), null, null, null, null, null, null, null, null]
        },
        {
          data: [null, null, null, null, ...variables.slice(4, 8).map(c => value[c.stat]), null, null, null, null]
        },
        {
          data: [null, null, null, null, null, null, null, null, ...variables.slice(8, 12).map(c => value[c.stat])]
        }
      ]
    }
  }
}
</script>
