<script>
import { mapGetters } from 'vuex'
import * as d3 from 'd3'
import d3Tip from 'd3-tip'
import * as L from 'leaflet'
import booleanPointInPolygon from '@turf/boolean-point-in-polygon'

import evt from '@/lib/events'
import variableMixin from '@/mixins/variable'
import { getCrossfilter } from '@/lib/crossfilter'

export default {
  name: 'IceMapLayer',
  mixins: [variableMixin],
  props: {
    name: {
      type: String,
      required: true
    },
    layer: {
      type: Object,
      required: false
    },
    setBounds: {
      type: Boolean,
      required: false,
      default: false
    },
    getFill: {
      type: Function,
      required: false,
      default: () => 'red'
    },
    getValue: {
      type: Function,
      required: false,
      default: () => null
    },
    selected: {
      type: Object,
      required: false,
      default: null
    }
  },
  data () {
    return {
      data: null,
      container: null,
      dim: null,
      tip: d3Tip()
        .attr('class', 'd3-tip')
    }
  },
  computed: {
    ...mapGetters(['variable', 'themeType', 'overlayFeature']),
    path () {
      const map = this.map
      function projectPoint (x, y) {
        const point = map.latLngToLayerPoint(new L.LatLng(y, x))
        this.stream.point(point.x, point.y)
      }
      const transform = d3.geoTransform({ point: projectPoint })
      return d3.geoPath().projection(transform) // .pointRadius(this.pointRadius)
    },
    map () {
      return this.$parent.map
    },
    disableClick () {
      return this.$parent.disableClick
    },
    zoomLevel () {
      return this.$parent.zoomLevel
    },
    pointRadius () {
      return this.zoomLevel - 2
    }
  },
  mounted () {
    // console.log(`map-layer(${this.name}):mounted`)
    this.dim = getCrossfilter().dimension(d => d.id)
    window.dim = this.dim
    evt.$on('map:zoom', this.render)
    evt.$on('map:render', this.renderFill)

    this.$parent.svg.style('pointer-events', 'none')
    this.container = this.$parent.svg
      .select('g')
      .append('g')
      .attr('class', 'ice-map-layer')
    this.container.call(this.tip)

    if (this.layer) {
      this.loadLayer(this.layer)
    }

    this.setTipHtml()
    this.render()
  },
  beforeDestroy () {
    // console.log(`map-layer(${this.name}):beforeDestroy`)
    if (this.dim) this.dim.dispose()
    evt.$off('map:zoom', this.render)
    evt.$off('map:render', this.renderFill)
    this.tip.destroy()
    this.container.selectAll('*').remove()
    this.container.remove()
    this.data = null
  },
  watch: {
    variable () {
      // console.log(`map-layer(${this.name}):watch variable`)
      this.setTipHtml()
    },
    layer () {
      // console.log(`map-layer(${this.name}):watch layer`)
      if (!this.layer) return this.clearLayer()
      return this.loadLayer(this.layer)
    },
    selected () {
      // console.log(`map-layer(${this.name}):watch selected`)
      this.renderSelected()
    },
    overlayFeature () {
      this.filterOverlayFeature()
    }
  },
  methods: {
    filterOverlayFeature () {
      if (this.overlayFeature && this.data) {
        const polygons = this.overlayFeature.geometry
        const filteredFeatures = this.data.features.filter(d => {
          return booleanPointInPolygon(d.geometry.coordinates, polygons)
        })
        const filterFeatureIds = filteredFeatures.map(d => d.id)
        this.dim.filterFunction(d => filterFeatureIds.includes(d))
      } else {
        console.log('no overlay feature')
        this.dim.filterAll()
      }
      evt.$emit('xf:filter')
      evt.$emit('map:render')
      evt.$emit('filter:render')
    },
    setTipHtml () {
      if (this.themeType === 'gage') {
        this.tip.html(d => `
          <strong>ID: ${d.id}</strong><br>
          ${this.variable.label}: ${typeof this.getValue(d) === 'object' ? this.valueFormatter(this.getValue(d).mean) + ` ${this.variable.units || ''}` : 'N/A'}
        `)
      } else if (this.themeType === 'huc12') {
        this.tip.html(d => {
          let x = `
            <strong>HUC12: ${d.properties.huc12}</strong><br>
            ${this.variable.label} = ${typeof this.getValue(d) === 'object' ? this.valueFormatter(this.getValue(d).mean) + ` ${this.variable.units || ''}` : 'N/A'}
          `
          if (isFinite(d.properties.p_value)) {
            x += `<br>Alteration p-Value = ${d.properties.p_value && d.properties.p_value < 0.0001 ? '< 0.0001' : d.properties.p_value.toFixed(4)}`
          }
          return x
        })
      }
    },
    loadLayer (layer) {
      // console.log(`map-layer(${this.name}):loadLayer`, layer)
      if (!layer) return

      this.container
        .selectAll('circle')
        .remove()

      return this.$http.get(`${layer.url}`)
        .then(response => response.data)
        .then((data) => {
          this.data = Object.freeze(data)
          this.render()
        })
    },
    clearLayer () {
      this.container
        .selectAll('circle')
        .remove()
    },
    projectPoint (d) {
      const latLng = new L.LatLng(d.geometry.coordinates[1], d.geometry.coordinates[0])
      return this.map.latLngToLayerPoint(latLng)
    },
    render () {
      // console.log(`map-layer(${this.name}):render`)
      if (!this.data) return

      const vm = this
      const tip = this.tip

      const features = this.data.features || []
      this.container
        .selectAll('circles')
        .remove()

      const circles = this.container
        .selectAll('circle')
        .data(features, d => d.id)

      circles.enter()
        .append('circle')
        .on('click', function (d) {
          !vm.disableClick && vm.$emit('click', d)
          this.parentNode.appendChild(this) // move to front
        })
        .on('mouseenter', function (d) {
          if (!vm.selected) {
            // move to front if nothing selected
            this.parentNode.appendChild(this)
          } else {
            // move to 2nd from front, behind selected
            const lastChild = this.parentNode.lastChild
            this.parentNode.insertBefore(this, lastChild)
          }

          d3.select(this)
            .attr('r', vm.pointRadius * 2)

          tip.show(d, this)
        })
        .on('mouseout', function (d) {
          d3.select(this)
            .attr('r', vm.pointRadius)
          tip.hide(d, this)
        })
        .merge(circles)
        .attr('r', this.pointRadius)
        .each(function (d) {
          const point = vm.projectPoint(d)
          d3.select(this)
            .attr('cx', d => point.x)
            .attr('cy', d => point.y)
        })

      circles.exit().remove()

      this.renderFill()
    },
    renderFill () {
      // console.log(`map-layer(${this.name}):renderFill`)
      this.container
        .selectAll('circle')
        .style('fill', this.getFill)
        .style('display', d => this.getValue(d) && this.getValue(d).count > 0 ? 'inline' : 'none')
    },
    renderSelected () {
      // console.log(`map-layer(${this.name}):renderSelected`)
      this.container
        .selectAll('circle')
        .classed('selected', this.isSelected)
    },
    isSelected (feature) {
      return !!this.selected && this.selected.id === feature.id
    }
  },
  render: function (h) {
    return null
  }
}
</script>

<style>
g.ice-map-layer > circle {
  cursor: pointer;
  pointer-events: visible;
}

g.ice-map-layer > circle.selected {
  stroke-width: 2px;
  stroke: red;
}

.d3-tip {
  line-height: 1;
  padding: 10px;
  background: rgba(255, 255, 255, 0.8);
  color: #000;
  border-radius: 2px;
  pointer-events: none;
  font-family: sans-serif;
  z-index: 1000;
}
</style>
