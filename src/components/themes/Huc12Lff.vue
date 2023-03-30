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

const lffCategories = ['7Q2', '7Q10', '30Q5', '30Q20']
const lffStats = ['7Day2yr', '7Day10yr', '30Day5yr', '30Day20yr']

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
            type: 'column'
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 2,
            valueSuffix: ' log10[cms]',
            shared: true,
            headerFormat: '<span>Statistic: <b>{point.key}</b></span><br/>',
            pointFormat: '<span style="color:{point.color}">\u25CF</span> Bias Correction: <b>{point.y}</b><br/>'
          },
          xAxis: {
            categories: lffCategories,
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
            type: 'column'
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 2,
            shared: true,
            headerFormat: '<span>Statistic: <b>{point.key}</b></span><br/>'
          },
          xAxis: {
            categories: lffCategories,
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
          data: lffCategories.map(c => value[`Corr_${c}`])
        }
      ]
      this.charts.stats.series = [
        {
          data: lffStats.map(c => value[`huc_${c}_Est_Corr`]),
          tooltip: {
            pointFormat: '<span style="color:{point.color}">\u25CF</span> Estimate: <b>{point.y}</b><br/>',
            valueSuffix: ' log10[cms]'
          }
        },
        {
          type: 'errorbar',
          data: lffStats.map(c => [value[`huc_${c}_Lwr_Corr`], value[`huc_${c}_Upr_Corr`]]),
          tooltip: {
            pointFormat: '&nbsp;&nbsp;&nbsp;95% CI: <b>{point.low} to {point.high} log10[cms]</b><br/>'
          }
        }
      ]
    }
  }
}
</script>
