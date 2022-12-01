<template>
  <ice-feature-container v-if="selected" @close="$emit('close')" :loading="loading" :error="error">
    <template v-slot:title>
      Selected HUC12: {{selected.id}}
    </template>

    <div v-if="!loading && !error && dataset">
      <ice-huc12-properties-box :properties="dataset.properties"></ice-huc12-properties-box>

      <ice-feature-box>
        <template v-slot:title>Hydrologic Alteration Summary</template>
        <v-list dense>
          <v-list-item>
            <v-list-item-content class="align-start" width="20">p-value:</v-list-item-content>
            <v-list-item-content class="align-end">{{ dataset.properties.p_value }}</v-list-item-content>
          </v-list-item>
        </v-list>
      </ice-feature-box>

      <ice-feature-box>
        <template v-slot:title>Flow Duration Curves</template>
        <highcharts class="chart" :options="charts.flow"></highcharts>
      </ice-feature-box>

      <ice-feature-box>
        <template v-slot:title>Flow Volume Curves</template>
        <highcharts class="chart" :options="charts.vol"></highcharts>
      </ice-feature-box>

      <ice-feature-box>
        <template v-slot:title>Ecochange Category</template>
        <highcharts class="chart" :options="charts.ecochange"></highcharts>
      </ice-feature-box>

      <ice-feature-box>
        <template v-slot:title>Ecochange Value</template>
        <highcharts class="chart" :options="charts.eco_val"></highcharts>
      </ice-feature-box>

      <ice-feature-box>
        <template v-slot:title>Ecochange Ratio</template>
        <highcharts class="chart" :options="charts.eco_ratio"></highcharts>
      </ice-feature-box>

      <ice-feature-box>
        <template v-slot:title>Net Streamflow Change</template>
        <highcharts class="chart" :options="charts.net_change"></highcharts>
      </ice-feature-box>
    </div>
  </ice-feature-container>
</template>

<script>
import highcharts from 'highcharts'
import { ascending } from 'd3'
import themeSelect from '@/mixins/themeSelect'

const categories = {
  ecochange: ['D', 'S']
}

export default {
  name: 'Huc12Hydroalt',
  mixins: [themeSelect],
  data () {
    return {
      charts: {
        flow: {
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
            valueDecimals: 1,
            valueSuffix: ' cfs',
            shared: true,
            headerFormat: '<span style="font-size: 10px">Exceedance Probability: {point.key}%</span><br/>'
          },
          xAxis: {
            type: 'linear',
            title: {
              text: 'Exceedance Probability'
            }
          },
          yAxis: {
            type: 'logarithmic',
            title: {
              text: 'Streamflow (cfs)'
            }
          },
          series: []
        },
        vol: {
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
            valueDecimals: 1,
            valueSuffix: ' ft3',
            shared: true,
            headerFormat: '<span style="font-size: 10px">Exceedance Probability: {point.key}%</span><br/>'
          },
          xAxis: {
            type: 'linear',
            title: {
              text: 'Exceedance Probability'
            }
          },
          yAxis: {
            type: 'linear',
            title: {
              text: 'Flow Volume (ft3)'
            }
          },
          series: []
        },
        ecochange: {
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
            valueDecimals: 1,
            valueSuffix: ' ft3',
            shared: true,
            headerFormat: '<span style="font-size: 10px">Exceedance Probability: {point.key}%</span><br/>'
          },
          xAxis: {
            type: 'linear',
            title: {
              text: 'Exceedance Probability'
            }
          },
          yAxis: {
            type: 'category',
            categories: categories.ecochange,
            title: {
              text: 'Eco-Deficit or Surplus'
            }
          },
          series: []
        },
        eco_val: {
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
            valueDecimals: 1,
            valueSuffix: ' ft3',
            shared: true,
            headerFormat: '<span style="font-size: 10px">Exceedance Probability: {point.key}%</span><br/>'
          },
          xAxis: {
            type: 'linear',
            title: {
              text: 'Exceedance Probability'
            }
          },
          yAxis: {
            type: 'linear',
            title: {
              text: 'Ecochange Value (ft3)'
            }
          },
          series: []
        },
        eco_ratio: {
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
            valueDecimals: 1,
            shared: true,
            headerFormat: '<span style="font-size: 10px">Exceedance Probability: {point.key}%</span><br/>'
          },
          xAxis: {
            type: 'linear',
            title: {
              text: 'Exceedance Probability'
            }
          },
          yAxis: {
            type: 'linear',
            title: {
              text: 'Ecochange Ratio'
            }
          },
          series: []
        },
        net_change: {
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
            valueDecimals: 1,
            shared: true,
            headerFormat: '<span style="font-size: 10px">Exceedance Probability: {point.key}%</span><br/>'
          },
          xAxis: {
            type: 'linear',
            title: {
              text: 'Exceedance Probability'
            }
          },
          yAxis: {
            type: 'linear',
            title: {
              text: 'Net Streamflow Change'
            }
          },
          series: []
        }
      }
    }
  },
  methods: {
    updateCharts () {
      this.clearCharts()
      const values = this.values.map(d => {
        return {
          ...d,
          exceedance_probs: +d.exceedance_probs
        }
      })
      values.sort((a, b) => ascending(a.exceedance_probs, b.exceedance_probs))
      this.charts.flow.series = [
        {
          name: 'Pre-alteration',
          data: values.map(d => {
            return [d.exceedance_probs, d.pre]
          }),
          type: 'line',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 2
          }
        }, {
          name: 'Post-alteration',
          data: values.map(d => {
            return [d.exceedance_probs, d.post]
          }),
          type: 'line',
          color: 'orangered',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 2
          }
        }
      ]
      this.charts.vol.series = [
        {
          name: 'Pre-alteration',
          data: values.map(d => {
            return [d.exceedance_probs, d.pre_int]
          }),
          type: 'line',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 2
          }
        }, {
          name: 'Post-alteration',
          data: values.map(d => {
            return [d.exceedance_probs, d.post_int]
          }),
          type: 'line',
          color: 'orangered',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 2
          }
        }
      ]
      this.charts.ecochange.series = [
        {
          name: 'Ecochange',
          data: values.map(d => {
            return [
              d.exceedance_probs,
              d.ecochange !== 'N/A'
                ? categories.ecochange.indexOf(d.ecochange)
                : null
            ]
          }),
          type: 'line',
          color: 'black',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 2
          }
        }
      ]
      this.charts.eco_val.series = [
        {
          name: 'Ecochange Value',
          data: values.map(d => {
            return [d.exceedance_probs, d.eco_val]
          }),
          type: 'line',
          color: 'black',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 2
          }
        }
      ]
      this.charts.eco_ratio.series = [
        {
          name: 'Ecochange Ratio',
          data: values.map(d => {
            return [d.exceedance_probs, d.eco_ratio]
          }),
          type: 'line',
          color: 'black',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 2
          }
        }
      ]
      this.charts.net_change.series = [
        {
          name: 'Net Streamflow Change',
          data: values.map(d => {
            return [d.exceedance_probs, d.net_change]
          }),
          type: 'line',
          color: 'black',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 2
          }
        }
      ]
    }
  }
}
</script>
