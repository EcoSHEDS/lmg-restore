<template>
  <div class="mt-4 d-flex align-center">
    <div class="text-right" style="width:80px;">Flow Type:</div>
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
  name: 'EcoflowsFlowtype',
  data () {
    return {
      options: [
        {
          id: 'obs',
          label: 'Observed'
        }, {
          id: 'syn',
          label: 'Synthetic'
        }
      ]
    }
  },
  computed: {
    value: {
      get () {
        return this.$store.state.ecoflowsFlowtype
      },
      set (value) {
        this.update(value)
      }
    }
  },
  methods: {
    ...mapActions(['setEcoflowsFlowtype']),
    async update (value) {
      await this.setEcoflowsFlowtype(value)
    }
  }
}
</script>
