import { timeFormat } from 'd3'
import download from 'downloadjs'

import { getCrossfilter } from '@/lib/crossfilter.js'

const json2csv = require('json2csv')

export function downloadDataset (filtered, theme) {
  const xf = getCrossfilter()
  let data
  if (filtered) {
    data = xf.allFiltered()
  } else {
    data = xf.all()
  }

  if (!data || data.length === 0) {
    return Promise.reject(new Error('No data available to download'))
  }

  const d = new Date()

  const dataFields = Object.keys(data[0])
  dataFields.splice(dataFields.findIndex(d => d === '$index'), 1) // remove '$index' column

  const dataCsv = json2csv.parse(data, { fields: dataFields })

  let variables = [
    { id: 'id', label: 'Unique gage or HUC12 ID' },
    { id: 'lat', label: 'Latitude' },
    { id: 'lon', label: 'Longitude' }
  ]
  if (theme.dimensions.decade) {
    variables.push({ id: 'decade', label: 'Decade' })
  }
  if (theme.dimensions.signif) {
    variables.push({ id: 'signif', label: 'Significant (p < 0.05) trend results only (if TRUE then trend slope columns will only include significant (p >= 0.05) results; otherwise all trend slopes are included regardless of p-value; does not affect columns from other datasets which will have the same values for signif=TRUE or FALSE)' })
  }
  variables = [...variables, ...theme.variables]
  const variableLines = variables.map(d => `# ${d.id}: ${d.label}${d.units ? ' (' + d.units + ')' : ''}`)

  const headerLines = [
    '# USGS LMGWSC Data Visualization Tool',
    `# Downloaded At: ${timeFormat('%m/%d/%Y %H:%M:%S')(d)}`,
    '#',
    `# Dataset: ${theme.title}`,
    '#',
    '# Citation(s):',
    ...theme.citations.map(d => `# "${d.text}" ${d.url}`),
    '#',
    '# Column Descriptions:',
    ...variableLines,
    '#',
    '# \n'
  ]

  const header = headerLines.join('\n')
  const csv = header + dataCsv

  download(csv, `usgs-lmgwsc-${timeFormat('%Y%m%d-%H%M%S')(d)}.csv`, 'text/csv')

  return Promise.resolve()
}
