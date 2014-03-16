if typeof process is 'object' and process.title is 'node'
  chai = require 'chai' unless chai
  parser = require '../lib/vgl-compiler'
else
  parser = require 'vgl-compiler/lib/vgl-compiler.js'

parse = (source, expect) ->
  result = null
  describe source, ->
    it '✓ ok', ->
      result = parser.parse source
      #console.log result
      chai.expect(result).to.be.an 'object'
    it '✓ matched', ->
      # sort b/c order doesn't really matter
      for key, val of result
        if val.sort? then val.sort()
      for key, val of expect
        if val.sort? then val.sort()
      chai.expect(result).to.eql expect

describe 'VGL-to-CCSS Compiler', ->
  
  it 'should provide a parse method', ->
    chai.expect(parser.parse).to.be.a 'function'


  # @rows @cols
  # ===============================================================
  
  describe '/* Rows Cols */', ->

    parse """    
            @grid-rows "A B C";
            @grid-cols "title   score12"
          """
        ,
          ccss: [
            '@virtual "A" "B" "C" "score12" "title"'
          ]
          vfl: [
            '@v |["A"]["B"]["C"]| in(::) chain-width(::[width]) chain-height chain-x(::[x])'
            '@h |["title"]["score12"]| in(::) chain-height(::[height]) chain-width chain-y(::[y])'
          ]
    
    parse """
            @grid-rows "-A~-~B-C~" gap([gap]) !strong;
            @grid-cols "-100-col3~-~";
          """
        ,
          ccss: [
            '@virtual "A" "B" "C" "col3"'
          ]
          vfl: [
            '@v |-["A"]~-~["B"]-["C"]~| in(::) chain-width(::[width]) chain-height chain-x(::[x]) gap([gap]) !strong'
            '@h |-100-["col3"]~-~| in(::) chain-height(::[height]) chain-width chain-y(::[y])'
          ]
          
    parse """
            @grid-rows "-Title~-~Score-Girls~Controls~" gap([gap]);
          """
        ,
          ccss: [
            '@virtual "Controls" "Girls" "Score" "Title"' # alphabetical
          ]
          vfl: [
            '@v |-["Title"]~-~["Score"]-["Girls"]~["Controls"]~| in(::) chain-width(::[width]) chain-height chain-x(::[x]) gap([gap])'
          ]
  
  
  # @grid-template
  # ===============================================================
  
  describe '/* Template', ->  
    
    describe 'basics */', ->
    
      parse """
              @grid-template simple "ab"; // basic 2 cols
            """
          ,
            ccss: [
              '@virtual "simple-a" "simple-b"'
              '::[simple-md-width] == ::[width] / 2 !require'
              '::[simple-md-height] == ::[height] !require'                
              '"simple-a"[width] == ::[simple-md-width]'
              '"simple-b"[width] == ::[simple-md-width]'
              '"simple-a"[height] == ::[simple-md-height]'    
              '"simple-b"[height] == ::[simple-md-height]'
            ]
            vfl: [
              '@h ["simple-a"]["simple-b"]'
              '@h |["simple-a"] in(::)'              
              '@v |["simple-a"] in(::)'
              '@v |["simple-b"] in(::)'
              '@h ["simple-b"]| in(::)'
              '@v ["simple-a"]| in(::)'
              '@v ["simple-b"]| in(::)'
            ]
      

      parse """
              @grid-template 1 
                "a"
                "b" gap(100) outer-gap([grid-margin]); // w/ options
            """
          ,
            ccss: [
              "@virtual \"1-a\" \"1-b\"",
              "::[1-md-width] <= ::[width] !require",
              "::[1-md-height] <= ::[height] / 2 !require",
              "\"1-a\"[width] == ::[1-md-width]",
              "\"1-b\"[width] == ::[1-md-width]",
              "\"1-a\"[height] == ::[1-md-height]",
              "\"1-b\"[height] == ::[1-md-height]"
            ]
            vfl: [
              "@v [\"1-a\"]-[\"1-b\"] gap(100)",
              "@h |-[\"1-a\"] in(::) gap([grid-margin])",
              "@h |-[\"1-b\"] in(::) gap([grid-margin])",
              "@v |-[\"1-a\"] in(::) gap([grid-margin])",
              "@h [\"1-a\"]-| in(::) gap([grid-margin])",
              "@h [\"1-b\"]-| in(::) gap([grid-margin])",
              "@v [\"1-b\"]-| in(::) gap([grid-margin])"
            ]

      parse """
              @grid-template nyt 
                "11111444"
                "22233444"
                "55555555";
            """
          ,
            ccss: [
              '@virtual "nyt-1" "nyt-2" "nyt-3" "nyt-4" "nyt-5"' # alphabetical
              '::[nyt-md-width] == ::[width] / 8 !require'
              '::[nyt-md-height] == ::[height] / 3 !require'
              "\"nyt-1\"[width] == ::[nyt-md-width] * 5",
              "\"nyt-2\"[width] == ::[nyt-md-width] * 3",
              "\"nyt-3\"[width] == ::[nyt-md-width] * 2",
              "\"nyt-4\"[width] == ::[nyt-md-width] * 3",
              "\"nyt-5\"[width] == ::[nyt-md-width] * 8",
              "\"nyt-1\"[height] == ::[nyt-md-height]",
              "\"nyt-2\"[height] == ::[nyt-md-height]",
              "\"nyt-3\"[height] == ::[nyt-md-height]",
              "\"nyt-4\"[height] == ::[nyt-md-height] * 2",
              "\"nyt-5\"[height] == ::[nyt-md-height]"
            ]
            vfl: [
              "@v [\"nyt-1\"][\"nyt-2\"]",
              "@v [\"nyt-2\"][\"nyt-5\"]",
              "@v [\"nyt-1\"][\"nyt-3\"]",
              "@v [\"nyt-3\"][\"nyt-5\"]",
              "@v [\"nyt-4\"][\"nyt-5\"]",
              "@h [\"nyt-1\"][\"nyt-4\"]",
              "@h [\"nyt-2\"][\"nyt-3\"]",
              "@h [\"nyt-3\"][\"nyt-4\"]",
              "@h |[\"nyt-1\"] in(::)",
              "@h |[\"nyt-2\"] in(::)",
              "@h |[\"nyt-5\"] in(::)",
              "@v |[\"nyt-1\"] in(::)",
              "@v |[\"nyt-4\"] in(::)",
              "@h [\"nyt-4\"]| in(::)",
              "@h [\"nyt-5\"]| in(::)",
              "@v [\"nyt-5\"]| in(::)"
            ]
  
  
  ## @grid-areas
  ## ===============================================================
  #
  #describe '/* Areas */', ->
  #
  #  parse """
  #          @grid-areas "title  price"
  #                      "desc   desc"
  #                      "meta   .";
  #        """
  #      ,
  #        [
  #          '@h |["1"]["2"]["3"]| in(::) chain-top(::[top]);'
  #          '@h |["4"]["5"]["6"]| in(::);'
  #          '@h |["7"]["8"]["9"]| in(::) chain-bottom(::[bottom]);'
  #          '"1" {width:==}'
  #          '@v |["1"]["4"]["7"]| in(::) chain-left(::[left]);'
  #          '@v |["2"]["5"]["8"]| in(::);'
  #          '@v |["3"]["6"]["9"]| in(::) chain-right(::[right]);'
  #        ]
  #  
  #  parse """
  #          @grid-areas "1 2 3"
  #                      "4 5 6"
  #                      "7 8 9" gap(8) outer-gap(16);
  #        """
  #      ,
  #        [
  #          '@h |-["1"]-["2"]-["3"]-| in(::) gap(8) outer-gap(16);'
  #          '@h |-["4"]-["5"]-["6"]-| in(::) gap(8) outer-gap(16);'
  #          '@h |-["7"]-["8"]-["9"]-| in(::) gap(8) outer-gap(16);'
  #          '@v |-["1"]-["4"]-["7"]-| in(::) gap(8) outer-gap(16);'
  #          '@v |-["2"]-["5"]-["8"]-| in(::) gap(8) outer-gap(16);'
  #          '@v |-["3"]-["6"]-["9"]-| in(::) gap(8) outer-gap(16);'
  #        ]
  #
  #
  ## playground
  ## ===============================================================
  #
  #"""
  #  
  #  .gallery {
  #    
  #    @grid-template large "11122334" gap([gap]) chain-width([grid-unit-x]) chain-height([grid-unit-y]);
  #    
  #    @grid-template-small "111"
  #                         "234";
  #    
  #    @if ::[width] >= 800 {
  #      .element1 {
  #        position: == "large-1"[position];
  #      }
  #    }
  #  
  #  }
  #  
  #"""
  
  
  
    