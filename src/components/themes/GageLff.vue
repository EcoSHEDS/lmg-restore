<template>
  <ice-feature-container v-if="selected" @close="$emit('close')" :loading="loading" :error="error">
    <template v-slot:title>
      Selected Gage: {{selected.id}}
    </template>

    <div v-if="!loading && !error && dataset">
      <ice-feature-box>
        <template v-slot:title>Gage Properties</template>
        <v-list dense>
          <v-list-item>
            <v-list-item-content class="align-start">Site Number</v-list-item-content>
            <v-list-item-content class="align-end">{{ dataset.properties.site_no }}</v-list-item-content>
          </v-list-item>
          <v-list-item>
            <v-list-item-content class="align-start">HUC12</v-list-item-content>
            <v-list-item-content class="align-end">{{ dataset.properties.huc12 }}</v-list-item-content>
          </v-list-item>
          <v-list-item>
            <v-list-item-content class="align-start">Latitude</v-list-item-content>
            <v-list-item-content class="align-end">{{ dataset.properties.dec_lat_va  }}</v-list-item-content>
          </v-list-item>
          <v-list-item>
            <v-list-item-content class="align-start">Longitude</v-list-item-content>
            <v-list-item-content class="align-end">{{ dataset.properties.dec_long_va  }}</v-list-item-content>
          </v-list-item>
          <v-list-item v-for="variableId in fields" :key="variableId">
            <v-list-item-content class="align-start" width="20">{{ variableById(variableId).label }}:</v-list-item-content>
            <v-list-item-content class="align-end">{{ variableFormatter(variableId)(dataset.values[0][variableId]) }} {{ variableById(variableId).units }}</v-list-item-content>
          </v-list-item>
        </v-list>
      </ice-feature-box>

      <ice-feature-box>
        <template v-slot:title>Low Flow Statistics</template>
        <highcharts class="chart" :options="charts.stats"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Spatial Bias Correction of Paired HUC12</template>
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
  name: 'GageLff',
  mixins: [themeSelect],
  data () {
    return {
      fields: [
        'number_decades',
        'hucCOV_gageCOV_DA_ratio',
        'gage_RecLen_7Day',
        'gage_RecLen_30Day'
      ],
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
          colors: ['#7cb5ec', '#90ed7d'],
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
          // legend: {
          //   enabled: false
          // },
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
          name: 'Gage',
          data: lffStats.map(c => value[`gage_${c}_Est_DACorr`]),
          tooltip: {
            pointFormat: '<span style="color:{point.color}">\u25CF</span> Gage Estimate: <b>{point.y}</b><br/>',
            valueSuffix: ' log10[cms]'
          }
        },
        {
          type: 'errorbar',
          data: lffStats.map(c => [value[`gage_${c}_Lwr_DACorr`], value[`gage_${c}_Upr_DACorr`]]),
          tooltip: {
            pointFormat: '&nbsp;&nbsp;&nbsp;95% CI: <b>{point.low} to {point.high} log10[cms]</b><br/>'
          }
        },
        {
          name: 'HUC12',
          data: lffStats.map((c, i) => value[`huc_${c}_Est_Corr_${lffCategories[i]}`]),
          tooltip: {
            pointFormat: '<span style="color:{point.color}">\u25CF</span> HUC12 Estimate: <b>{point.y}</b><br/>',
            valueSuffix: ' log10[cms]'
          }
        },
        {
          type: 'errorbar',
          data: lffStats.map((c, i) => [value[`huc_${c}_Lwr_Corr_${lffCategories[i]}`], value[`huc_${c}_Upr_Corr_${lffCategories[i]}`]]),
          tooltip: {
            pointFormat: '&nbsp;&nbsp;&nbsp;95% CI: <b>{point.low} to {point.high} log10[cms]</b><br/>'
          }
        }
      ]
    }
  }
}
</script>
