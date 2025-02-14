<template>
  <v-app>
    <!-- USGS header -->
    <header id="navbar" class="header-nav" role="banner">
      <div class="tmp-container">
        <div class="header-search">
          <a class="logo-header" href="https://www.usgs.gov/" title="USGS Home">
            <img src="img/usgs-logo.png" alt="USGS" class="img" border="0" height="50" />
          </a>
        </div>
      </div>
    </header>

    <v-app-bar dense app dark absolute style="margin-top:68px" v-if="$vuetify.breakpoint.mdAndUp">
      <v-toolbar-title class="headline">
        USGS <span v-if="$vuetify.breakpoint.xl">Lower Mississippi-Gulf Water Science Center</span><span v-else>LMGWSC</span> |
        <span class="font-weight-light">RESTORE Data Visualization Tool</span>
        <span style="font-size:50%;" class="pl-1">v{{ version }}</span>
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn text medium class="mx-2" @click="dialogs.welcome = true">
        <v-icon small left>mdi-home</v-icon> Welcome
      </v-btn>
      <v-btn text medium class="mx-2" @click="dialogs.help = true">
        <v-icon small left>mdi-help</v-icon> User's Guide
      </v-btn>
      <v-btn text medium class="mx-2" @click="dialogs.contact = true">
        <v-icon small left>mdi-email</v-icon> Contact
      </v-btn>
      <!-- <v-btn text medium class="mx-2" href="http://ecosheds.org" v-if="!usgs">
        <v-icon small left>mdi-home-import-outline</v-icon> ecosheds
      </v-btn> -->
      <!-- <v-btn text medium class="mx-2" v-if="debug" @click="goDebug">
        <v-icon small left>mdi-play</v-icon> go
      </v-btn> -->
    </v-app-bar>
    <v-app-bar app dense clipped-left dark absolute style="margin-top:68px"  v-else>
      <v-toolbar-title class="subheading">
        <span>LMGWSC RESTORE Data Visualization Tool</span>
      </v-toolbar-title>
    </v-app-bar>

    <v-content v-if="$vuetify.breakpoint.mdAndUp">
      <IceMap :basemaps="map.basemaps" :center="[31, -94]" :zoom="6">
        <IceMapLayer
          name="points"
          set-bounds
          :layer="layer"
          :getFill="getFill"
          :getValue="getValue"
          :selected="feature.selected"
          @click="selectFeature">
        </IceMapLayer>
      </IceMap>
      <v-container fluid fill-height class="align-stretch py-0 mt-4">
        <v-row>
          <v-col>
            <v-card width="500">
              <v-tabs
                v-model="tabs.active"
                class="ice-tabs-main"
                background-color="primary"
                dark
                slider-color="white">
                <v-tab ripple>
                  Dataset
                </v-tab>
                <v-tab ripple :disabled="!theme">
                  Layers
                </v-tab>
                <v-tab ripple :disabled="!theme">
                  Crossfilters
                </v-tab>
                <v-spacer></v-spacer>
                <v-btn icon small @click="collapse.tabs = !collapse.tabs" class="align-self-center mr-1">
                  <v-icon small v-if="!collapse.tabs">mdi-menu-up</v-icon>
                  <v-icon small v-else>mdi-menu-down</v-icon>
                </v-btn>

                <!-- DATASET -->
                <v-tab-item transition="false" reverse-transition="false">
                  <v-card class="ice-card elevation-10 pb-0" ref="dataset" v-if="!collapse.tabs">
                    <v-card-text v-if="theme" class="px-3">
                      <div class="title font-weight-bold grey--text text--darken-4">
                        <span v-if="theme">{{ theme.title }}</span>
                        <span v-else-if="error.theme">Failed to load dataset</span>
                        <span v-else>None</span>
                      </div>
                      <exceedance-dimension v-if="theme.dimensions.exceedance" class="mt-4"></exceedance-dimension>
                      <decade-dimension v-if="theme.dimensions.decade" class="mt-4"></decade-dimension>
                      <signif-dimension v-if="theme.dimensions.signif"></signif-dimension>
                      <ecoflows-region v-if="theme.id.startsWith('gage-ecoflows')"></ecoflows-region>
                      <ecoflows-flowtype v-if="theme.id.startsWith('gage-ecoflows')"></ecoflows-flowtype>
                      <!-- <pre>{{ theme.id }}</pre> -->
                      <div class="subheading mt-4" v-if="theme && theme.id === 'gage-primary' || theme.id === 'gage-qtrend'">
                        <v-icon small>mdi-information</v-icon> For trend test results, the decade slider sets the
                        starting point of the analysis period, which always ends in 2015 (e.g., if 1970s is selected, then trend results
                        are based on 1970-2015).
                      </div>

                      <v-divider class="my-4"></v-divider>

                      <div class="pt-8" v-if="theme.id === 'gage-qtrend'">
                        <trend-variable @update="setVariableById"></trend-variable>
                      </div>
                      <div v-else>
                        <div class="font-weight-bold text-subtitle-1 black--text mb-4">Color Variable</div>
                        <v-autocomplete
                          label="Select color variable..."
                          :items="mapVariables"
                          v-model="variable"
                          return-object
                          dense
                          outlined
                          item-value="id"
                          item-text="label"
                          :menu-props="{ closeOnClick: false, closeOnContentClick: false, openOnClick: false, maxHeight: 400 }"
                          class="mt-2"
                          hide-details
                        >
                          <template v-slot:item="{ item }">
                            <v-list-item-content class="pl-3 body-2" v-html="item.label"></v-list-item-content>
                            <v-tooltip right max-width="600">
                              <template v-slot:activator="{ on }">
                                <v-icon v-on="on" small color="grey lighten-1">mdi-information</v-icon>
                              </template>
                              {{ item.description }}
                            </v-tooltip>
                          </template>
                        </v-autocomplete>
                      </div>
                    </v-card-text>
                    <v-card-text v-else-if="error.theme">
                      <v-alert type="error" outlined class="mb-0">
                        <strong>Failed to load dataset</strong><br>
                        Try another dataset or <a @click="dialogs.contact=true">contact us</a> if the problem persists.
                      </v-alert>
                    </v-card-text>
                    <v-card-text v-else>
                      <v-alert type="info" outlined class="mb-0">
                        <strong>No dataset has been loaded</strong><br>
                        Open the Dataset Browser to load a dataset.
                      </v-alert>
                    </v-card-text>
                    <v-divider></v-divider>
                    <v-card-actions class="pa-3">
                      <v-btn small outlined text color="primary" @click="dialogs.theme = true">
                        <v-icon left small>mdi-folder-open</v-icon> Dataset Browser
                      </v-btn>
                      <v-spacer></v-spacer>
                      <v-btn small outlined text color="primary" v-if="theme" @click="dialogs.download = true">
                        <v-icon left small>mdi-download</v-icon> Download
                      </v-btn>
                    </v-card-actions>
                  </v-card>
                </v-tab-item>

                <!-- LAYERS -->
                <v-tab-item transition="false" reverse-transition="false">
                  <v-card v-show="!collapse.tabs" v-if="theme">
                    <v-card-text class="pb-2">
                      <v-autocomplete
                        :items="overlays"
                        v-model="overlay"
                        dense
                        return-object
                        item-value="id"
                        item-text="label"
                        outlined
                        class="mb-4 mt-2"
                        hide-details
                        deletable-chips
                        clearable
                        label="Select spatial layer..."
                      ></v-autocomplete>

                      <v-divider v-if="overlayFeature" class="my-4"></v-divider>
                      <div v-if="overlayFeature" class="d-flex">
                        <div class="black--text body-1">
                          Selected: <strong>{{ overlayFeature.properties.label }}</strong>
                        </div>

                        <v-spacer></v-spacer>

                        <v-btn icon small @click="setOverlayFeature(null)" class="align-self-center mr-1">
                          <v-icon small>mdi-close</v-icon>
                        </v-btn>
                      </div>
                      <v-alert type="warning" outlined v-else-if="overlay" class="font-weight-bold">
                        Click on a polygon to filter the points within it.
                      </v-alert>
                      <v-alert type="warning" outlined v-else class="font-weight-bold">
                        Select a layer to filter the map spatially.
                      </v-alert>
                    </v-card-text>
                  </v-card>
                </v-tab-item>

                <!-- CROSSFILTERS -->
                <v-tab-item transition="false" reverse-transition="false">
                  <v-card v-show="!collapse.tabs" v-if="theme">
                    <v-card-text class="pb-2">
                      <v-autocomplete
                        :items="filterVariables"
                        v-model="filters"
                        multiple
                        dense
                        return-object
                        item-value="id"
                        item-text="label"
                        chips
                        small-chips
                        outlined
                        class="mb-4 mt-2"
                        hide-details
                        deletable-chips
                        clearable
                        label="Select crossfilter variable(s)...">
                        <template v-slot:item="data">
                          <v-list-item-action>
                            <v-checkbox small :value="data.attrs.inputValue"></v-checkbox>
                          </v-list-item-action>
                          <v-list-item-content class="body-2" v-html="data.item.label"></v-list-item-content>
                        </template>
                      </v-autocomplete>
                      <ice-filter v-for="variable in filters" :key="variable.id" :variable="variable" @close="removeFilter(variable)"></ice-filter>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
              </v-tabs>
            </v-card>
          </v-col>
          <v-col>
            <ice-legend-box v-if="theme && variable" :collapse="collapse.legend" :counts="counts" @collapse="collapse.legend = !collapse.legend"></ice-legend-box>
          </v-col>
        </v-row>
      </v-container>
      <v-navigation-drawer
        :value="!!feature.selected"
        right
        temporary
        fixed
        hide-overlay
        stateless
        width="500"
        class="mt-0">
        <component v-if="theme" :is="themeComponentId" :selected="feature.selected" @close="selectFeature()"></component>
      </v-navigation-drawer>
    </v-content>

    <v-content v-else>
      <v-card>
        <v-card-text class="mt-4 black--text">
          <div class="text-center mb-8">
            <h2 class="headline">Welcome to the U.S. Geological Survey Lower Mississippi-Gulf Water Science Center's <br> RESTORE Data Visualization Tool</h2>
          </div>

          <div class="mt-8">
            <v-alert type="error" class="my-8" outlined prominent>
              <div class="title">This site is not designed for mobile devices.</div>
              Please use a laptop or desktop with a larger screen size (>960px wide).
            </v-alert>
          </div>
          <div>
            <video loop controls width="100%">
            <source src="video/crossfilters.mp4" type="video/mp4">
              Sorry, your browser doesn't support embedded videos.
            </video>
          </div>

          <v-divider class="mb-4"></v-divider>

          <h4 class="title">Project Background</h4>
          <p class="body-1">
            Human alteration of waterways has impacted the minimum and maximum streamflows in more than 86% of monitored streams nationally
            and may be the primary cause for ecological impairment in river and stream ecosystems. Restoration of freshwater inflows can
            positively affect shellfish, fisheries, habitat, and water quality in streams, rivers, and estuaries. Increasingly, State and
            local decision-makers and Federal agencies are turning their attention to the restoration of flows as part of a holistic approach
            to restoring water quality and habitat and to protecting and replenishing living coastal and marine resources and the livelihoods
            that depend on them.
          </p>
          <p class="body-1">
            In 2017, the U.S. Geological Survey and U.S. Environmental Protection Agency began collaborating on a comprehensive, large-scale,
            state-of-the-science foundational
            project (RESTORE) to provide vital information on the timing and delivery of freshwater to streams, bays, estuaries, and wetlands
            of the Gulf Coast. The information generated through this project will provide local, State, and Federal partners the
            ability to evaluate how streamflow withdrawals and reservoir operations throughout a watershed may alter streamflow metrics
            and freshwater inputs to an estuary.
          </p>
          <p class="body-1">
            <a href="https://www.usgs.gov/centers/lmg-water/science/streamflow-alteration-assessments-support-bay-and-estuary-restoration-gulf" target="_blank">
              Click here to read more about the RESTORE project
            </a>
          </p>

          <h4 class="title">About the application</h4>
          <p class="body-1">
            This application provides a set of interactive data visualization tools to explore datasets generated by USGS researchers
            for the RESTORE project. The purpose of this tool is to help stakeholders, decision makers and other interested users
            access these datasets and develop a better understanding of spatial and temporal streamflow patterns in
            the Lower Mississippi-Gulf Region.
          </p>
          <p class="body-1">
            This application was built by <a href="https://walkerenvres.com" target="_blank">Walker Environmental Research</a><v-icon small class="align-self-center">mdi-open-in-new</v-icon>
            and is an adaptation of the <a href="http://ice.ecosheds.org" target="_blank">Interactive Catchment Explorer</a><v-icon small class="align-self-center">mdi-open-in-new</v-icon>,
            which is part of the <a href="https://usgs.gov/apps/ecosheds" target="_blank">Spatial Hydro-Ecological Decision System (EcoSHEDS)</a>.
          </p>

          <v-divider class="mb-4"></v-divider>

          <disclaimer></disclaimer>
        </v-card-text>
      </v-card>
    </v-content>

    <!-- welcome -->
    <v-dialog
      v-model="dialogs.welcome"
      max-width="1000"
      v-if="$vuetify.breakpoint.mdAndUp"
      scrollable>
      <v-card>
        <v-toolbar dark dense color="primary">
          <v-toolbar-title><v-icon left>mdi-home</v-icon> Welcome</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.welcome = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text class="mt-4 black--text">
          <div class="text-center mb-8">
            <h2 class="headline">Welcome to the U.S. Geological Survey Lower Mississippi-Gulf Water Science Center's <br> RESTORE Data Visualization Tool</h2>
          </div>

          <div class="text-center my-8">
            <div>
              <video loop controls width="400">
              <source src="video/crossfilters.mp4" type="video/mp4">
                Sorry, your browser doesn't support embedded videos.
              </video>
            </div>
            <div class="mt-8">
              <v-btn
                color="success"
                x-large
                @click="dialogs.welcome = false; dialogs.theme = true">
                Get Started <v-icon>mdi-chevron-double-right</v-icon>
              </v-btn>
            </div>
          </div>

          <v-divider class="mb-4"></v-divider>

          <h4 class="title">Project Background</h4>
          <p class="body-1">
            Human alteration of waterways has impacted the minimum and maximum streamflows in more than 86% of monitored streams nationally
            and may be the primary cause for ecological impairment in river and stream ecosystems. Restoration of freshwater inflows can
            positively affect shellfish, fisheries, habitat, and water quality in streams, rivers, and estuaries. Increasingly, State and
            local decision-makers and Federal agencies are turning their attention to the restoration of flows as part of a holistic approach
            to restoring water quality and habitat and to protecting and replenishing living coastal and marine resources and the livelihoods
            that depend on them.
          </p>
          <p class="body-1">
            In 2017, the U.S. Geological Survey and U.S. Environmental Protection Agency began collaborating on a comprehensive, large-scale,
            state-of-the-science foundational
            project (RESTORE) to provide vital information on the timing and delivery of freshwater to streams, bays, estuaries, and wetlands
            of the Gulf Coast. The information generated through this project will provide local, State, and Federal partners the
            ability to evaluate how streamflow withdrawals and reservoir operations throughout a watershed may alter streamflow metrics
            and freshwater inputs to an estuary.
          </p>
          <p class="body-1">
            <a href="https://www.usgs.gov/centers/lmg-water/science/streamflow-alteration-assessments-support-bay-and-estuary-restoration-gulf" target="_blank">
              Click here to read more about the RESTORE project
            </a>
          </p>

          <h4 class="title">About the application</h4>
          <p class="body-1">
            This application provides a set of interactive data visualization tools to explore datasets generated by USGS researchers
            for the RESTORE project. The purpose of this tool is to help stakeholders, decision makers and other interested users
            access these datasets and develop a better understanding of spatial and temporal streamflow patterns in
            the Lower Mississippi-Gulf Region.
          </p>
          <p class="body-1">
            This application was built by <a href="https://walkerenvres.com" target="_blank">Walker Environmental Research</a><v-icon small class="align-self-center">mdi-open-in-new</v-icon>
            and is an adaptation of the <a href="http://ice.ecosheds.org" target="_blank">Interactive Catchment Explorer</a><v-icon small class="align-self-center">mdi-open-in-new</v-icon>
            which is part of the <a href="https://usgs.gov/apps/ecosheds" target="_blank">Spatial Hydro-Ecological Data System (EcoSHEDS)</a>.
          </p>

          <v-divider class="mb-4"></v-divider>

          <disclaimer></disclaimer>
        </v-card-text>

        <v-divider class="mb-4"></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.welcome = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- contact -->
    <v-dialog
      v-model="dialogs.contact"
      max-width="600"
      scrollable>
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title><v-icon left>mdi-email</v-icon> Contact Information</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.contact = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text class="mt-8 black--text">
          <p class="body-1">Questions, comments, problems? Please contact one of the team members listed below.</p>
          <h4>USGS Contact</h4>
          <p class="ml-4">
            Kirk D. Rodgers, PhD<br>
            Hydrologist, and Eastern Region Diversity Subcouncil Chairman<br>
            <a href="https://www.usgs.gov/centers/lmg-water" target="_blank">U.S. Geological Survey Lower Mississippi-Gulf Water Science Center</a><br>
            E-mail: <a href="mailto:krodgers@usgs.gov">krodgers@usgs.gov</a>
          </p>
          <h4>Application Developer and Administrator</h4>
          <p class="ml-4">
            Jeffrey D. Walker, PhD<br>
            Environmental Data Scientist<br>
            <a href="https://walkerenvres.com" target="_blank">Walker Environmental Research, LLC</a><br>
            E-mail: <a href="mailto:jeff@walkerenvres.com">jeff@walkerenvres.com</a>
          </p>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.contact = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- user guide -->
    <v-dialog
      v-model="dialogs.help"
      scrollable
      max-width="1600">
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title><v-icon left>mdi-help</v-icon> User's Guide</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.help = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text class="mt-4">
          <user-guide></user-guide>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.help = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- download -->
    <v-dialog
      v-model="dialogs.download"
      max-width="1000"
      scrollable>
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title><v-icon left>mdi-download</v-icon> Download</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.download = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <!-- <v-card-text class="mt-4">
          <h2>Instructions</h2>
          <p class="body-1">
            The current dataset can be downloaded using the buttons below.
          </p>
          <p class="body-1">
            Clicking on either button will trigger the application to download two files:
          </p>
          <ol class="body-1">
            <li>Dataset file in comma separate values (CSV) format.</li>
            <li>Metadata file describing each column in the dataset</li>
          </ol>
        </v-card-text>

        <v-divider></v-divider> -->

        <v-card-text class="my-4 black--text" v-if="theme">
          <v-container>
            <v-row>
              <v-col class="text-center">
                <h2>Complete Dataset</h2>
                <p class="font-italic my-8">Includes all gages or HUC12s regardless of any filters that are currently set, and data for all decades.</p>
                <v-btn color="success" @click="downloadDataset(false)">
                  <v-icon>mdi-download</v-icon> Complete Dataset (CSV)
                </v-btn>
              </v-col>
              <v-divider vertical></v-divider>
              <v-col class="text-center">
                <h2>Filtered Dataset</h2>
                <p class="font-italic my-8">Includes only gages or HUC12s that meet any existing filters, and only data for the current decade.</p>
                <v-btn color="success" @click="downloadDataset(true)">
                  <v-icon>mdi-download</v-icon> Filtered Dataset (CSV)
                </v-btn>
              </v-col>
            </v-row>
          </v-container>

          <v-divider class="my-8"></v-divider>

          <h2 v-if="theme.citations.length > 1">Citations </h2>
          <h2 v-else>Citation </h2>
          <p v-for="citation in theme.citations" :key="citation.text">
            {{citation.text}} <a :href="citation.url" target="_blank">{{ citation.url }}</a>
          </p>

          <v-divider class="my-8"></v-divider>

          <disclaimer></disclaimer>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.download = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- dataset browser -->
    <v-dialog
      v-model="dialogs.theme"
      max-width="1200"
      scrollable>
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title>Dataset Browser</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.theme = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text class="pl-0">
          <v-row justify="space-between">
            <v-col sm="4">
              <v-treeview
                v-model="themes.selected"
                :active.sync="themes.active"
                :open.sync="themes.open"
                :items="themes.options"
                activatable
                return-object
                open-on-click
                dense
                open-all>
                <template v-slot:prepend="{ item, open }">
                  <v-icon v-if="item.children">
                    {{ open ? 'mdi-folder-open' : 'mdi-folder' }}
                  </v-icon>
                  <v-icon v-else-if="item.id === 'gage-primary' || item.id === 'huc12-primary'">
                    {{ 'mdi-star' }}
                  </v-icon>
                  <v-icon v-else>
                    {{ 'mdi-table' }}
                  </v-icon>
                </template>
                <template v-slot:label="{ item }">
                  <span v-if="item.children" class="subtitle-1">
                    {{item.name}}
                  </span>
                  <span v-else-if="item.id === 'gage-primary' || item.id === 'huc12-primary'" class="font-weight-bold">
                    {{item.name}}
                  </span>
                  <span v-else>
                    {{item.name}}
                  </span>
                </template>
              </v-treeview>
            </v-col>
            <v-divider vertical></v-divider>
            <v-col>
              <div v-for="theme in themes.active" :key="theme.id" class="pt-4 black--text">
                <h2 class="mb-2">{{theme.title}}</h2>
                <p>{{theme.description}}</p>
                <div class="text-center my-8">
                  <v-btn large color="green" dark @click="selectTheme(theme)" :loading="loading.theme">
                    Load Dataset
                    <v-icon right>mdi-chevron-double-right</v-icon>
                  </v-btn>
                </div>
                <v-divider class="my-4"></v-divider>
                <div v-if="theme.citations">
                  <h3 v-if="theme.citations.length > 1">Citations: </h3>
                  <h3 v-else>Citation: </h3>
                  <div v-for="citation in theme.citations" :key="citation.text" class="mt-4">
                    {{citation.text}} <a :href="citation.url" target="_blank">{{ citation.url }}</a>
                  </div>
                </div>
              </div>

              <div class="pt-4 black--text" style="width:100%" v-if="themes.active.length === 0">
                <v-alert color="success" prominent outlined icon="mdi-chevron-left">
                  Select a dataset from the list.
                </v-alert>

                <h4 class="title">About</h4>
                <p class="body-2">
                  Use the Dataset Browser to load a specific dataset into the application. Only one dataset can be loaded at any given time.
                </p>
                <p class="body-2">
                  Datasets are organized into two groups: Streamflow Gages and HUC12 Basins. The first group provides data associated
                  with USGS streamflow gaging stations. The second group provides data
                  associated with the pour points of all 12-digit hydrologic unit code (HUC12) basins in the region.
                </p>
                <p class="body-2">
                  Primary Datasets (<v-icon small>mdi-star</v-icon>) include a combination of the key variables
                  from the datasets within each group (either Streamflow Gages or HUC12 Basins).
                </p>
                <p class="body-2">
                  The other datasets (<v-icon small>mdi-table</v-icon>) include all available variables for that dataset. Each of these datasets
                  corresponds to one of the datasets posted to the
                  <a href="https://www.sciencebase.gov/catalog/item/59b7ed9be4b08b1644df5d50" target="_blank">ScienceBase repository</a>
                  for the RESTORE project.
                </p>
                <h4 class="title">First Time Here?</h4>
                <p class="body-2">
                  Start with one of the Primary Datasets to begin exploring key metrics associated with either the Streamflow Gages or
                  HUC12 Basins. To explore a specific dataset in more detail, return here and load that dataset to access all available variables.
                </p>
              </div>
            </v-col>
          </v-row>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.theme = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- USGS footer -->
    <footer class="footer">
      <div class="tmp-container">
        <div class="footer-doi">
          <ul class="menu nav">
            <li class="first leaf menu-links menu-level-1"><a href="https://www.doi.gov/privacy">DOI Privacy Policy</a>
            </li>
            <li class="leaf menu-links menu-level-1"><a href="https://www.usgs.gov/laws/policies_notices.html">Legal</a>
            </li>
            <li class="leaf menu-links menu-level-1"><a
                href="https://www2.usgs.gov/laws/accessibility.html">Accessibility</a></li>
            <li class="leaf menu-links menu-level-1"><a href="https://www.usgs.gov/sitemap.html">Site Map</a></li>
            <li class="last leaf menu-links menu-level-1"><a href="https://answers.usgs.gov/">Contact USGS</a></li>
          </ul>
        </div>

        <hr class="usgs">

        <div class="footer-doi">
          <ul class="menu nav">
            <li class="first leaf menu-links menu-level-1"><a href="https://www.doi.gov/">U.S. Department of the
                Interior</a></li>
            <li class="leaf menu-links menu-level-1"><a href="https://www.doioig.gov/">DOI Inspector General</a></li>
            <li class="leaf menu-links menu-level-1"><a href="https://www.whitehouse.gov/">White House</a></li>
            <li class="leaf menu-links menu-level-1"><a href="https://www.whitehouse.gov/omb/management/egov/">E-gov</a>
            </li>
            <li class="leaf menu-links menu-level-1"><a href="https://www.doi.gov/pmb/eeo/no-fear-act">No Fear Act</a>
            </li>
            <li class="last leaf menu-links menu-level-1"><a href="https://www2.usgs.gov/foia">FOIA</a></li>
          </ul>
        </div>
      </div>
    </footer>
  </v-app>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'

import IceMap from '@/components/IceMap'
import IceMapLayer from '@/components/IceMapLayer'
import IceFilter from '@/components/IceFilter'
import IceLegendBox from '@/components/IceLegendBox'

import Disclaimer from '@/components/Disclaimer'

import DecadeDimension from '@/components/dimensions/DecadeDimension'
import SignifDimension from '@/components/dimensions/SignifDimension'
import ExceedanceDimension from '@/components/dimensions/ExceedanceDimension'

import EcoflowsRegion from '@/components/EcoflowsRegion'
import EcoflowsFlowtype from '@/components/EcoflowsFlowtype'

import TrendVariable from '@/components/TrendVariable'
import UserGuide from '@/components/UserGuide'

import GagePrimary from '@/components/themes/GagePrimary'
import GageCov from '@/components/themes/GageCov'
import GageQstat from '@/components/themes/GageQstat'
import GageQtrend from '@/components/themes/GageQtrend'
import GageEcoflows from '@/components/themes/GageEcoflows'
import GageSolar from '@/components/themes/GageSolar'
import Huc12Primary from '@/components/themes/Huc12Primary'
import Huc12Cov from '@/components/themes/Huc12Cov'
import Huc12Qquantile from '@/components/themes/Huc12Qquantile'
import Huc12Solar from '@/components/themes/Huc12Solar'
import Huc12Hydroalt from '@/components/themes/Huc12Hydroalt'
import Huc12Lff from '@/components/themes/Huc12Lff'
import GageLff from '@/components/themes/GageLff'

import { getValueById, getFilteredCount, getTotalCount } from '@/lib/crossfilter'
import themes from '@/assets/themes'
import evt from '@/lib/events'
import { groupVariables } from '@/lib/utils'
import { downloadDataset } from '@/lib/download'
import VariableMixin from '@/mixins/variable'
import ColorMixin from '@/mixins/color'

export default {
  name: 'App',
  mixins: [VariableMixin, ColorMixin],
  components: {
    IceMap,
    IceMapLayer,
    IceFilter,
    IceLegendBox,
    Disclaimer,

    DecadeDimension,
    SignifDimension,
    ExceedanceDimension,

    EcoflowsRegion,
    EcoflowsFlowtype,

    TrendVariable,
    UserGuide,
    GagePrimary,
    GageCov,
    GageQstat,
    GageQtrend,
    GageEcoflows,
    GageSolar,
    Huc12Primary,
    Huc12Cov,
    Huc12Qquantile,
    Huc12Solar,
    Huc12Hydroalt,
    Huc12Lff,
    GageLff
  },
  data: () => ({
    debug: process.env.NODE_ENV === 'development',
    version: process.env.VUE_APP_VERSION,
    // debug: false,
    collapse: {
      dataset: false,
      tabs: false,
      legend: false,
      debug: false
    },
    tabs: {
      active: 0
    },
    filters: [],
    rightSidebar: {
      open: true
    },
    dialogs: {
      theme: false,
      welcome: true,
      contact: false,
      help: false,
      download: false
    },
    loading: {
      theme: false
    },
    error: {
      theme: null
    },
    themes: {
      active: [],
      selected: [],
      open: themes.map(d => d.id),
      options: themes
    },
    feature: {
      selected: null
    },
    counts: {
      total: 0,
      filtered: 0
    },
    map: {
      basemaps: [
        {
          name: 'ESRI World Imagery',
          visible: true,
          url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
        },
        {
          name: 'USGS Imagery',
          visible: false,
          url: 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSImageryOnly/MapServer/tile/{z}/{y}/{x}',
          attribution: '<a href="http://www.doi.gov">U.S. Department of the Interior</a> | <a href="http://www.usgs.gov">U.S. Geological Survey</a> | <a href="http://www.usgs.gov/laws/policies_notices.html">Policies</a>'
        },
        {
          name: 'USGS Topo',
          visible: false,
          url: 'https://basemap.nationalmap.gov/ArcGIS/rest/services/USGSTopo/MapServer/tile/{z}/{y}/{x}',
          attribution: '<a href="http://www.doi.gov">U.S. Department of the Interior</a> | <a href="http://www.usgs.gov">U.S. Geological Survey</a> | <a href="http://www.usgs.gov/laws/policies_notices.html">Policies</a>'
        },
        // {
        //   name: 'USGS Hydrography',
        //   visible: false,
        //   url: 'https://basemap.nationalmap.gov/arcgis/rest/services/USGSHydroCached/MapServer/tile/{z}/{y}/{x}',
        //   attribution: '<a href="http://www.doi.gov">U.S. Department of the Interior</a> | <a href="http://www.usgs.gov">U.S. Geological Survey</a> | <a href="http://www.usgs.gov/laws/policies_notices.html">Policies</a>'
        // },
        {
          name: 'OpenStreetMap',
          visible: false,
          url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        },
        {
          name: 'No Basemap',
          visible: false,
          url: '',
          attribution: ''
        }
      ]
    },
    legendSettings: false
  }),
  computed: {
    ...mapGetters(['theme', 'ecoflowsTheme', 'variables', 'layer', 'colorScheme', 'colorInvert', 'overlays', 'overlayFeature']),
    themeComponentId () {
      if (!this.theme) return null
      if (this.theme.id.startsWith('gage-ecoflows')) return 'gage-ecoflows'
      return this.theme.id
    },
    variable: {
      get () {
        return this.$store.getters.variable
      },
      set (value) {
        return this.$store.dispatch('setVariable', value)
      }
    },
    overlay: {
      get () {
        return this.$store.getters.overlay
      },
      set (value) {
        return this.$store.dispatch('setOverlay', value)
      }
    },
    mapVariables () {
      return groupVariables(this.variables.filter(d => d.map))
    },
    filterVariables () {
      return groupVariables(this.variables.filter(d => d.filter))
    }
  },
  mounted () {
    console.log(process.env.PACKAGE_VERSION)
    // if (!this.theme) this.dialogs.welcome = true
    evt.$on('xf:filter', this.updateCounts)
  },
  beforeDestroy () {
    evt.$off('xf:filter', this.updateCounts)
  },
  watch: {
    variable () {
      this.variable && evt.$emit('map:render')
    },
    overlay (val, old) {
      this.setOverlayFeature(null)
    },
    ecoflowsTheme (val, old) {
      if (val) {
        this.selectEcoflowsTheme({ id: 'gage-ecoflows' })
      }
    }
  },
  methods: {
    ...mapActions(['setOverlayFeature']),
    async goDebug () {
      const themes = [
        ...this.themes.options[0].children,
        ...this.themes.options[1].children
      ]

      const loadVariable = (variable) => {
        return new Promise((resolve) => {
          this.filters = [variable]
          this.setVariableById(variable.id)
          setTimeout(() => {
            resolve(true)
          }, 2000)
        })
      }

      for (let iTheme = 0; iTheme < themes.length; iTheme++) {
        console.log(`theme: ${themes[iTheme].id}`)
        await this.selectTheme(themes[iTheme])
          .then(() => {
            return new Promise(async (resolve) => { // eslint-disable-line
              const variables = this.variables.filter(d => d.filter)
              await loadVariable(variables.find(d => d.default) || variables[0])
              for (let i = 1; i < variables.length; i++) {
                console.log(`variable: ${variables[i].id}`)
                await loadVariable(variables[i])
              }
              resolve(true)
            })
          })
      }
    },
    updateCounts () {
      this.counts.total = getTotalCount()
      this.counts.filtered = getFilteredCount()
    },
    selectTheme (theme) {
      this.loading.theme = true
      this.error.theme = null

      return this.clearTheme()
        .then(() => this.$store.dispatch('loadTheme', theme))
        .then((theme) => {
          this.error.theme = null
          this.updateCounts()
        })
        .catch((err) => {
          console.error(err)
          this.error.theme = 'Failed to load theme'
        })
        .finally(() => {
          evt.$emit('theme:set')
          this.loading.theme = false
          this.dialogs.theme = false
        })
    },
    selectEcoflowsTheme (theme) {
      this.error.theme = null

      this.selectFeature()
      this.clearFilters()

      return this.$store.dispatch('loadTheme', theme)
        .then(() => {
          this.error.theme = null
          this.updateCounts()
        })
        .catch((err) => {
          console.error(err)
          this.error.theme = 'Failed to load theme'
        })
        .finally(() => {
          evt.$emit('theme:set')
        })
    },
    clearTheme () {
      this.selectFeature()
      this.clearFilters()
      return this.$store.dispatch('clearTheme')
        .then(() => this.updateCounts())
    },
    selectFeature (feature) {
      if (!feature || this.feature.selected === feature) {
        this.feature.selected = null
      } else {
        this.feature.selected = feature
        // TODO: fetch drainage area layer
      }
    },
    getValue (feature) {
      const value = getValueById(feature.id)
      if (this.variable && this.variable.type === 'cat') {
        const values = Object.entries(value.counts).filter(d => d[1] > 0)
        if (values.length > 0) {
          value.mean = values[0][0]
        }
      }
      return value
    },
    getFill (feature) {
      const value = this.getValue(feature)
      return value ? this.colorScale(this.variableScale(value.mean)) : null
    },
    removeFilter (variable) {
      this.filters.splice(this.filters.findIndex(v => v === variable), 1)
    },
    clearFilters () {
      this.filters = []
    },
    setVariableById (id) {
      const variable = this.$store.getters.variableById(id)
      if (!variable) return
      this.variable = variable
      this.updateCounts()
    },
    downloadDataset (filtered) {
      downloadDataset(filtered, this.theme)
        .catch((err) => alert(`Failed to download dataset\n\n${err}`))
    }
  }
}
</script>

<style>
.v-dialog__content.v-dialog__content--active {
  align-items: start;
}
.v-tabs.ice-tabs-main > .v-window > .v-window__container {
  max-height: calc(100vh - 255px);
  overflow-y: auto;
}
.v-toolbar__content {
  padding-left: 12px;
  padding-right: 12px;
}
</style>
