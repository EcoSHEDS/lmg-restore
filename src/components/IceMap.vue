<template>
  <div class="ice-map-container">
    <l-map ref="map" :options="{ ...options, zoomControl: false }">
      <l-control-zoom position="topright"></l-control-zoom>
      <l-control-layers position="topright"></l-control-layers>
      <l-tile-layer
        v-for="tile in basemaps"
        :key="tile.name"
        :name="tile.name"
        :visible="tile.visible"
        :url="tile.url"
        :attribution="tile.attribution"
        layer-type="base">
      </l-tile-layer>
      <l-geo-json
        v-if="overlay"
        ref="overlay"
        :name="overlay.id"
        :geojson="overlayFeatures"
        :options="overlayOptions"
        :options-style="overlayStyle"
      >
        <l-tooltip></l-tooltip>
      </l-geo-json>
    </l-map>
    <slot v-if="ready"></slot>
  </div>
</template>

<script>
import { LMap, LTileLayer, LGeoJson, LControlZoom, LControlLayers } from 'vue2-leaflet'
import { mapActions, mapGetters } from 'vuex'
import * as L from 'leaflet'
import * as d3 from 'd3'

import evt from '@/lib/events'

export default {
  name: 'IceMap',
  props: {
    options: {
      type: Object,
      required: false,
      default: () => {}
    },
    center: {
      type: Array,
      required: false,
      default: () => [42, -72]
    },
    zoom: {
      type: Number,
      required: false,
      default: 8
    },
    basemaps: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  components: {
    LMap,
    LTileLayer,
    LGeoJson,
    LControlZoom,
    LControlLayers
  },
  data () {
    return {
      ready: false,
      map: null,
      disableClick: false,
      bounds: null,
      zoomLevel: null,
      dim: null,
      overlayFeatures: [],
      overlayOptions: {
        interactive: true,
        onEachFeature: (feature, layer) => {
          layer.bindTooltip(`<h3>${feature.properties.label}</h3>`)
          // layer.bringToFront()
          layer.on('mouseover', () => {
            layer.setStyle({
              fillColor: '#0000ff',
              fillOpacity: 0.2
            })
          })
          layer.on('mouseout', () => {
            layer.setStyle({
              fillColor: '#ff0000',
              fillOpacity: 0
            })
          })
          layer.on('click', (evt) => {
            const feature = evt.target.feature
            if (feature === this.overlayFeature) {
              this.setOverlayFeature(null)
            } else {
              this.setOverlayFeature(feature)
              layer.bringToFront()
            }
          })
        }
      }
    }
  },
  computed: {
    ...mapGetters(['overlay', 'overlayFeature'])
  },
  watch: {
    overlay () {
      this.loadOverlay()
    },
    overlayFeature () {
      this.restyleOverlayFeatures()
    }
  },
  mounted () {
    // console.log('map:mounted')
    this.map = this.$refs.map.mapObject
    this.map.setView(this.center, this.zoom)

    this.zoomLevel = this.map.getZoom()

    let moveTimeout
    this.map.on('movestart', () => {
      window.clearTimeout(moveTimeout)
      this.disableClick = true
    })
    this.map.on('moveend', () => {
      // console.log('map:moveend', this.map.getCenter().toString())
      moveTimeout = setTimeout(() => {
        this.disableClick = false
      }, 100)
    })
    this.map.on('zoomend', () => {
      this.zoomLevel = this.map.getZoom()
      evt.$emit('map:zoom')
    })

    const svgLayer = L.svg()
    this.map.addLayer(svgLayer)

    this.svg = d3.select(svgLayer.getPane()).select('svg')
      .classed('leaflet-zoom-animated', false)
      .classed('leaflet-zoom-hide', true)
      .classed('map', true)
      .attr('pointer-events', null)
      .style('z-index', 201)

    this.ready = true
    this.loadOverlay()
  },
  methods: {
    ...mapActions(['setOverlayFeature']),
    async loadOverlay () {
      this.overlayFeatures = []
      if (!this.overlay) return
      const { url } = this.overlay
      const response = await fetch(url)
      const geojson = await response.json()
      this.overlayFeatures = geojson.features
    },
    overlayStyle () {
      return {
        fillOpacity: 0,
        weight: 2,
        color: 'white'
      }
    },
    restyleOverlayFeatures () {
      if (!this.$refs.overlay) return
      const map = this.$refs.overlay.mapObject
      const layers = map.getLayers()
      layers.forEach(layer => {
        const feature = layer.feature
        if (feature === this.overlayFeature) {
          layer.setStyle({
            color: 'orangered'
          })
        } else {
          layer.setStyle({
            color: 'white'
          })
        }
      })
    }
  }
}
</script>

<style>
.ice-map-container {
  position: absolute;
  width: 100%;
  height: 100%;
  left: 0;
  top: 0;
  z-index: 0;
}
</style>
