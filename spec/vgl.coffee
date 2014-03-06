if typeof process is 'object' and process.title is 'node'
  chai = require 'chai' unless chai
  parser = require '../lib/vgl-compiler'
else
  parser = require 'vgl-compiler/lib/vgl-compiler.js'

parse = (source, expect) ->
  result = null
  describe source, ->
    it 'should do something', ->
      result = parser.parse source
      chai.expect(result).to.be.an 'array'
    it 'should match expected', ->
      chai.expect(result).to.eql expect

describe 'VGL-to-CCSS Compiler', ->
  
  it 'should provide a parse method', ->
    chai.expect(parser.parse).to.be.a 'function'

  # Basics
  # --------------------------------------------------
  
  describe '/* Rows */', ->

    parse """
            @grid-rows "A B C"; // simple connection
          """
        ,
          [
            '@v |["A"]["B"]["C"]| in(::) chain-width(::[width]);'
          ]
    
    parse """
            @grid-rows "-A~-~B-C~" gap([gap]); // simple connection
          """
        ,
          [
            '@v |-["A"]~-~["B"]-["C"]~| in(::) gap([gap]) chain-width(::[width]);'
          ]
          
    parse """
            @grid-rows "-Title~-~Score-Girls~Controls~" gap([gap]); // simple connection
          """
        ,
          [
            '@v |-["Title"]~-~["Score"]-["Girls"]~["Controls"]~| in(::) gap([gap]) chain-width(::[width]);'
          ]
  
  describe '/* Areas */', ->

    parse """
            @grid-areas "1 2 3"
                        "4 5 6"
                        "7 8 9";
          """
        ,
          [
            '@h |["1"]["2"]["3"]| in(::);'
            '@h |["4"]["5"]["6"]| in(::);'
            '@h |["7"]["8"]["9"]| in(::);'
            '@v |["1"]["4"]["7"]| in(::);'
            '@v |["2"]["5"]["8"]| in(::);'
            '@v |["3"]["6"]["9"]| in(::);'
          ]
    
    parse """
            @grid-areas "1 2 3"
                        "4 5 6"
                        "7 8 9" gap(8) outer-gap(16);
          """
        ,
          [
            '@h |-["1"]-["2"]-["3"]-| in(::) gap(8) outer-gap(16);'
            '@h |-["4"]-["5"]-["6"]-| in(::) gap(8) outer-gap(16);'
            '@h |-["7"]-["8"]-["9"]-| in(::) gap(8) outer-gap(16);'
            '@v |-["1"]-["4"]-["7"]-| in(::) gap(8) outer-gap(16);'
            '@v |-["2"]-["5"]-["8"]-| in(::) gap(8) outer-gap(16);'
            '@v |-["3"]-["6"]-["9"]-| in(::) gap(8) outer-gap(16);'
          ]
    