<template>
  <div class="black--text">
    Exceedance probability: {{ exceedanceValue }} %
    <v-slider
      v-model="value"
      :tick-labels="options"
      :max="options.length - 1"
      step="1"
      ticks="always"
      tick-size="2"
      track-color="primary"
      track-fill-color="primary"
      class="px-4 mt-10 dim-exceedance"
      hide-details
    >
    </v-slider>
  </div>
</template>

<script>
import { getCrossfilter } from '@/lib/crossfilter'
import evt from '@/lib/events'

export default {
  name: 'ExceedanceDimension',
  data () {
    return {
      value: 13,
      options: ['0.03', '0.05', '0.1', '0.2', '0.5', '1', '2', '5', '10', '20', '25', '30', '40', '50', '60', '70', '75', '80', '90', '95', '98', '99', '99.5', '99.8', '99.9', '99.95']
    }
  },
  computed: {
    exceedanceValue () {
      return this.options[this.value]
    }
  },
  watch: {
    value () {
      this.update()
    }
  },
  mounted () {
    const xf = getCrossfilter()
    this.dim = xf.dimension(d => d.exceedance_probs)
    evt.$on('theme:set', this.update)
  },
  beforeDestroy () {
    evt.$off('theme:set', this.update)
    this.dim.dispose()
  },
  methods: {
    update () {
      console.log('exceedance_probs', this.exceedanceValue)
      this.dim.filterExact(this.exceedanceValue)
      evt.$emit('map:render')
      evt.$emit('xf:filter')
      evt.$emit('filter:render')
    }
  }
}
</script>

<style>
.dim-exceedance > .v-input__control > .v-input__slot >  .v-slider > .v-slider__ticks-container > .v-slider__tick > .v-slider__tick-label {
  transform: rotate(-90deg) translate(2em,0) !important;
  position: relative !important;
}
</style>
