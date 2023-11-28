<template>
  <ice-feature-container v-if="selected" @close="$emit('close')" :loading="loading" :error="error">
    <template v-slot:title>
      Selected Station: {{selected.id}}
    </template>

    <div v-if="!loading && !error && dataset">
      <ice-feature-box>
        <template v-slot:title>Station Properties</template>
        <v-list dense>
          <v-list-item>
            <v-list-item-content class="align-start">Station ID</v-list-item-content>
            <v-list-item-content class="align-end">{{ dataset.properties.station_id }}</v-list-item-content>
          </v-list-item>
          <v-list-item v-if="dataset.properties.site_no">
            <v-list-item-content class="align-start">Gage Number</v-list-item-content>
            <v-list-item-content class="align-end">{{ dataset.properties.site_no }}</v-list-item-content>
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

      <!-- <ice-feature-box>
        <template v-slot:title>Low Flow Statistics</template>
        <highcharts class="chart" :options="charts.stats"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Spatial Bias Correction of Paired HUC12</template>
        <highcharts class="chart" :options="charts.bias"></highcharts>
      </ice-feature-box> -->
    </div>
  </ice-feature-container>
</template>

<script>
import themeSelect from '@/mixins/themeSelect'

export default {
  name: 'GageEcoflows',
  mixins: [themeSelect],
  computed: {
    fields () {
      return this.$store.state.theme.variables.map(d => d.id)
    }
  }
}
</script>
