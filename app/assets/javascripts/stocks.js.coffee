# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

ready = ->
  $('#chart_ctn').highcharts
    chart:
      alignTicks: false
    title:
      text: ''
    credits:
      enabled: false
    xAxis:
      categories: $('#chart_ctn').data 'xAxis_categories'
    yAxis: [
      title:
        text: '% Change Mean'
      labels:
        format: '{value}%'
    ,
      title:
        text: 'Reliability'
      labels:
        format: '{value}%'
      opposite: true
    ]
    series: [
      type: 'column'
      name: '% Change Mean'
      data: $('#chart_ctn').data 'mean_data'
    ,
      type: 'line'
      name: 'Reliability'
      data: $('#chart_ctn').data 'reliability_data'
      yAxis: 1
    ]

$(document).ready ready
$(document).on 'page:load', ready
