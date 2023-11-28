import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios'
import { csvParse, extent } from 'd3'

import { setData, clearCrossfilter, setVariable } from '@/lib/crossfilter'

Vue.use(Vuex)

const DECADES = ['1950', '1960', '1970', '1980', '1990', '2000']

export default new Vuex.Store({
  state: {
    theme: null,
    decade: null,
    variable: null,
    ecoflowsRegion: 'east',
    ecoflowsFlowtype: 'obs',
    settings: {
      color: {
        scheme: 'Viridis',
        type: 'continuous',
        invert: false
      }
    },
    overlays: [
      {
        id: 'states',
        label: 'State Boundaries',
        url: 'gis/states.geojson'
      },
      {
        id: 'huc4',
        label: 'HUC4 Basins',
        url: 'gis/huc4.geojson'
      },
      {
        id: 'huc8',
        label: 'HUC8 Basins',
        url: 'gis/huc8.geojson'
      },
      {
        id: 'alabama_shu',
        label: 'Alabama Strategic Habitat Units',
        url: 'gis/alabama_shu.geojson'
      },
      {
        id: 'ecoflows',
        label: 'Ecoflows Study Area',
        url: 'gis/ecoflows.geojson'
      },
      {
        id: 'mobile_tombigbee',
        label: 'Mobile-Tombigbee Study Area',
        url: 'gis/mobile_tombigbee.geojson'
      },
      {
        id: 'pearl_pascagoula',
        label: 'Pearl-Pascagoula Study Area',
        url: 'gis/pearl_pascagoula.geojson'
      }
    ],
    overlay: null,
    overlayFeature: null
  },
  getters: {
    theme: state => state.theme,
    themeType: state => {
      if (!state.theme) return null
      return state.theme.id.split('-')[0]
    },
    decade: state => state.decade,
    ecoflowsRegion: state => state.ecoflowsRegion,
    ecoflowsFlowtype: state => state.ecoflowsFlowtype,
    ecoflowsTheme: state => `gage-ecoflows-${state.ecoflowsFlowtype}-${state.ecoflowsRegion}`,
    decadeIndex: state => DECADES.indexOf(state.decade),
    variables: state => (state.theme ? state.theme.variables : []),
    variable: state => state.variable,
    variableById: state => id => {
      return state.theme ? state.theme.variables.find(v => v.id === id) : null
    },
    layer: state => (state.theme ? state.theme.layer : null),
    colorScheme: state => state.settings.color.scheme,
    colorType: state => state.settings.color.type,
    colorInvert: state => state.settings.color.invert,
    overlays: state => state.overlays,
    overlay: state => state.overlay,
    overlayFeature: state => state.overlayFeature
  },
  mutations: {
    SET_THEME (state, theme) {
      state.theme = theme
    },
    SET_DECADE (state, decade) {
      state.decade = decade
    },
    SET_ECOFLOWS_REGION (state, region) {
      state.ecoflowsRegion = region
    },
    SET_ECOFLOWS_FLOWTYPE (state, flowtype) {
      state.ecoflowsFlowtype = flowtype
    },
    SET_VARIABLE (state, variable) {
      state.variable = variable
    },
    SET_COLOR_SCHEME (state, scheme) {
      state.settings.color.scheme = scheme
    },
    SET_COLOR_TYPE (state, type) {
      state.settings.color.type = type
    },
    SET_COLOR_INVERT (state, invert) {
      state.settings.color.invert = invert
    },
    SET_OVERLAY (state, overlay) {
      state.overlay = overlay
    },
    SET_OVERLAY_FEATURE (state, overlayFeature) {
      state.overlayFeature = overlayFeature
    }
  },
  actions: {
    setDecade ({ commit }, decade) {
      commit('SET_DECADE', decade)
    },
    setEcoflowsRegion ({ commit }, region) {
      commit('SET_ECOFLOWS_REGION', region)
    },
    setEcoflowsFlowtype ({ commit }, flowtype) {
      console.log('setEcoflowsFlowtype', flowtype)
      commit('SET_ECOFLOWS_FLOWTYPE', flowtype)
    },
    clearTheme ({ commit }) {
      commit('SET_THEME', null)
      commit('SET_VARIABLE', null)
      clearCrossfilter()
      return Promise.resolve(null)
    },
    loadTheme ({ commit, dispatch }, theme) {
      console.log('loadTheme', theme)
      if (!theme) {
        return dispatch('clearTheme')
      }

      let themeId = theme.id
      if (themeId === 'gage-ecoflows') {
        themeId = this.getters.ecoflowsTheme
      }

      return axios.get(`/${themeId}/theme.json`)
        .then((response) => {
          const theme = response.data
          const variable = theme.variables.find(d => d.default) || theme.variables[0]

          return { theme, variable }
        })
        .then(({ theme, variable }) => {
          const numVariables = theme.variables
            .filter(v => v.type === 'num')
            .map(v => v.id)
          const catVariables = theme.variables
            .filter(v => v.type === 'cat')
            .map((v) => {
              return {
                id: v.id,
                map: new Map(v.scale.domain.map(d => [d.value, d.label]))
              }
            })
          return axios.get(theme.data.url)
            .then((response) => response.data)
            .then((csvString) => {
              return csvParse(csvString, (d, i) => {
                const x = {
                  $index: i,
                  id: d.id,
                  lat: d.lat,
                  lon: d.lon
                }

                if (theme.dimensions.decade) {
                  x.decade = d.decade
                }

                if (theme.dimensions.signif) {
                  x.signif = d.signif === 'TRUE'
                }

                if (theme.dimensions.exceedance) {
                  x.exceedance_probs = d.exceedance_probs.toString()
                }

                numVariables.forEach(v => {
                  x[v] = d[v] === '' ? null : +d[v]
                })

                catVariables.forEach(v => {
                  x[v.id] = d[v.id] === '' ? null : v.map.get(d[v.id])
                })

                return x
              })
            })
            .then(data => ({ theme, variable, data }))
        })
        .then(({ theme, variable, data }) => {
          // update variable extents
          theme.variables.forEach(v => {
            const values = data.map(d => d[v.id])
            v.scale.extent = extent(values)
            if (v.type === 'num') {
              v.scale.clipped = [
                v.scale.extent[0] < v.scale.domain[0],
                v.scale.extent[1] > v.scale.domain[1]
              ]
            }
          })

          return setData(data, theme.data.group.by)
            .then(() => {
              return { theme, variable, data }
            })
        })
        .then(({ theme, variable }) => {
          commit('SET_THEME', theme)
          return dispatch('setVariable', variable)
        })
    },
    setVariable ({ commit }, variable) {
      return setVariable(variable)
        .then(() => commit('SET_VARIABLE', variable))
    },
    setColorScheme ({ commit }, scheme) {
      return commit('SET_COLOR_SCHEME', scheme)
    },
    setColorType ({ commit }, type) {
      return commit('SET_COLOR_TYPE', type)
    },
    setColorInvert ({ commit }, invert) {
      return commit('SET_COLOR_INVERT', invert)
    },
    setOverlay ({ commit }, overlay) {
      return commit('SET_OVERLAY', overlay)
    },
    setOverlayFeature ({ commit }, overlayFeature) {
      return commit('SET_OVERLAY_FEATURE', overlayFeature)
    }
  }
})
