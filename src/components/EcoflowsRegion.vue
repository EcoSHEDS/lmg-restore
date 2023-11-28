<template>
  <div class="mt-4 d-flex align-center">
    <div class="text-right" style="width:80px">Region:</div>
    <v-btn-toggle v-model="value" dense class="ml-4" mandatory>
      <v-btn v-for="option in options" :key="option.id" :value="option.id">
        {{ option.label }}
      </v-btn>
    </v-btn-toggle>
  </div>
</template>

<script>
import { mapActions } from 'vuex'

export default {
  name: 'EcoflowsRegion',
  data () {
    return {
      options: [
        {
          id: 'east',
          label: 'East'
        }, {
          id: 'southeast',
          label: 'Southeast'
        }, {
          id: 'west',
          label: 'West'
        }
      ]
    }
  },
  computed: {
    value: {
      get () {
        return this.$store.state.ecoflowsRegion
      },
      set (value) {
        this.update(value)
      }
    }
  },
  methods: {
    ...mapActions(['setEcoflowsRegion']),
    async update (value) {
      await this.setEcoflowsRegion(value)
    }
  }
}
</script>
