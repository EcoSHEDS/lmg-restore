<template>
  <div>
    <v-checkbox
      v-model="value"
      hide-details>
      <template v-slot:label>
        <div class="subtitle-2">Significant Trend Results Only (p &lt; 0.05)</div>
      </template>
    </v-checkbox>
  </div>
</template>

<script>
import { getCrossfilter } from '@/lib/crossfilter'
import evt from '@/lib/events'

export default {
  name: 'SignifDimension',
  data () {
    return {
      value: false
    }
  },
  watch: {
    value () {
      this.update()
    }
  },
  mounted () {
    const xf = getCrossfilter()
    this.dim = xf.dimension(d => d.signif)
    window.xf = xf
    window.dim = this.dim
    evt.$on('theme:set', this.update)
  },
  beforeDestroy () {
    evt.$off('theme:set', this.update)
    this.dim.dispose()
  },
  methods: {
    update () {
      console.log('update', this.value)
      if (this.value) {
        this.dim.filterExact(this.value)
      } else {
        this.dim.filterAll()
      }
      evt.$emit('map:render')
      evt.$emit('xf:filter')
      evt.$emit('filter:render')
    }
  }
}
</script>
