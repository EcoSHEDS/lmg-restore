<template>
  <ice-feature-container v-if="selected" @close="$emit('close')" :loading="loading" :error="error">
    <template v-slot:title>
      Selected HUC12: {{selected.id}}
    </template>

    <div v-if="!loading && !error && dataset">
      <ice-huc12-properties-box :properties="dataset.properties"></ice-huc12-properties-box>
    </div>
  </ice-feature-container>
</template>

<script>
import highcharts from 'highcharts'

import themeSelect from '@/mixins/themeSelect'

export default {
  name: 'Huc12Hydroalt',
  mixins: [themeSelect],
  data () {
    return {
    }
  },
  methods: {
  }
}
</script>
