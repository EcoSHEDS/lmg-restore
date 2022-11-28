<template>
  <div>
    <v-toolbar dense dark color="primary">
      <h3 class="headline mb-0"><slot name="title"></slot></h3>
      <v-spacer></v-spacer>
      <v-btn icon color="white" @click="$emit('close')">
        <v-icon>mdi-close</v-icon>
      </v-btn>
    </v-toolbar>
    <v-card-text>
      <div v-if="loading" class="title">
        <div class="title my-4">
          <v-progress-circular
            :size="30"
            :width="5"
            color="primary"
            indeterminate
            class="mx-4"
          ></v-progress-circular>
          Loading
        </div>
      </div>
      <div v-else-if="error">
        <v-alert type="error" outlined prominent>
          <div class="title">Server Error</div>
          Failed to get dataset for selected feature.
        </v-alert>
      </div>
      <slot></slot>

      <ice-feature-box v-if="!error && !loading">
        <template v-slot:title><span v-if="theme.citations.length > 1">Citations</span><span v-else>Citation</span></template>
        <v-card-text class="pb-1 black--text">
          <p v-for="citation in theme.citations" :key="citation.text">
            {{ citation.text }} <a :href="citation.url" target="_blank">{{ citation.url }}</a>.
          </p>
        </v-card-text>
      </ice-feature-box>
    </v-card-text>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

import IceFeatureBox from '@/components/IceFeatureBox'

export default {
  name: 'IceFeatureContainer',
  props: ['loading', 'error'],
  components: {
    IceFeatureBox
  },
  computed: {
    ...mapGetters(['theme'])
  }
}
</script>
