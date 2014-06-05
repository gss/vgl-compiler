if window?
  parser = require 'vgl-compiler'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'

{expect} = chai


parse = (source, expectation, pending) ->
  itFn = if pending then xit else it

  describe source, ->
    result = null

    itFn '✓ ok', ->
      result = parser.parse source
      #console.log result
      expect(result).to.be.an 'object'
    itFn '✓ matched', ->
      # sort b/c order doesn't really matter
      for key, val of result
        if val.sort? then val.sort()
      for key, val of expectation
        if val.sort? then val.sort()
      expect(result).to.eql expectation


# Helper function for expecting errors to be thrown when parsing.
#
# @param source [String] VGL statements.
# @param message [String] This should be provided when a rule exists to catch
# invalid syntax, and omitted when an error is expected to be thrown by the PEG
# parser.
# @param pending [Boolean] Whether the spec should be treated as pending.
#
expectError = (source, message, pending) ->
  itFn = if pending then xit else it

  describe source, ->
    predicate = 'should throw an error'
    predicate = "#{predicate} with message: #{message}" if message?

    itFn predicate, ->
      exercise = -> parser.parse source
      expect(exercise).to.throw Error, message


describe 'VGL-to-CCSS Compiler', ->
  
  it 'should provide a parse method', ->
    expect(parser.parse).to.be.a 'function'


  # @rows @cols
  # ===============================================================
  
  describe '/* Rows Cols */', ->

    ###
      - top-gap... outer-left-gap...
      - in()
    ###
    
    parse """    
            @grid-cols "title - score12"
              gap(12);
          """
        ,
          ccss: [
            '@virtual "score12" "title"'
          ]
          vfl: [
            '@h |["title"]-["score12"]| in(::) chain-height(::[height]) chain-width chain-y(::[y]) gap(12)'
          ]
    
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
    
    ###
    parse """    
            @grid-cols "col1 - col2"
              chain-width(>= 1)
              gap(12); // overwrite chain options
          """
        ,
          ccss: [
            '@virtual "col1" "col2"'
          ]
          vfl: [
            '@h |["col1"]-["col2"]| in(::) chain-height(::[height]) chain-width(>= 1) chain-y(::[y]) gap(12)'
          ]
    ###
  
  
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
              @grid-template simple "ab" in("area"); // in()
            """
          ,
            ccss: [
              '@virtual "simple-a" "simple-b"'
              '::[simple-md-width] == "area"[width] / 2 !require'
              '::[simple-md-height] == "area"[height] !require'                
              '"simple-a"[width] == ::[simple-md-width]'
              '"simple-b"[width] == ::[simple-md-width]'
              '"simple-a"[height] == ::[simple-md-height]'    
              '"simple-b"[height] == ::[simple-md-height]'
            ]
            vfl: [
              '@h ["simple-a"]["simple-b"]'
              '@h |["simple-a"] in("area")'              
              '@v |["simple-a"] in("area")'
              '@v |["simple-b"] in("area")'
              '@h ["simple-b"]| in("area")'
              '@v ["simple-a"]| in("area")'
              '@v ["simple-b"]| in("area")'
            ]
      

      parse """
              @grid-template 1 
                "a"
                "b" gap(100) outer-gap([grid-margin]); // w/ gaps v.1
            """
          ,
            ccss: [
              "@virtual \"1-a\" \"1-b\"",
              "::[1-md-width] <= (::[width] - [grid-margin] - [grid-margin]) !require",
              "::[1-md-height] <= (::[height] - [grid-margin] - [grid-margin] - 100) / 2 !require",
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
              @grid-template 1 
                "a"
                "b" h-gap([h]) v-gap([v]) right-gap([r]); // w/ gaps v.2
            """
          ,
            ccss: [
              "@virtual \"1-a\" \"1-b\"",
              "::[1-md-width] <= (::[width] - [r] - [h]) !require",
              "::[1-md-height] <= (::[height] - [v] - [v] - [v]) / 2 !require",
              "\"1-a\"[width] == ::[1-md-width]",
              "\"1-b\"[width] == ::[1-md-width]",
              "\"1-a\"[height] == ::[1-md-height]",
              "\"1-b\"[height] == ::[1-md-height]"
            ]
            vfl: [
              "@v [\"1-a\"]-[\"1-b\"] gap([v])"
              "@h |-[\"1-a\"] in(::) gap([h])"
              "@h |-[\"1-b\"] in(::) gap([h])"
              "@v |-[\"1-a\"] in(::) gap([v])"
              "@h [\"1-a\"]-| in(::) gap([r])"
              "@h [\"1-b\"]-| in(::) gap([r])"
              "@v [\"1-b\"]-| in(::) gap([v])"
            ]
            
      parse """
              @grid-template 1 
                "a"
                "b" top-gap(1) right-gap(2) bottom-gap(3) left-gap(4); // w/ gaps v.3
            """
          ,
            ccss: [
              "@virtual \"1-a\" \"1-b\"",
              "::[1-md-width] <= (::[width] - 2 - 4) !require",
              "::[1-md-height] <= (::[height] - 1 - 3) / 2 !require",
              "\"1-a\"[width] == ::[1-md-width]",
              "\"1-b\"[width] == ::[1-md-width]",
              "\"1-a\"[height] == ::[1-md-height]",
              "\"1-b\"[height] == ::[1-md-height]"
            ]
            vfl: [
              "@v [\"1-a\"][\"1-b\"]",
              "@h |-[\"1-a\"] in(::) gap(4)",
              "@h |-[\"1-b\"] in(::) gap(4)",
              "@v |-[\"1-a\"] in(::) gap(1)",
              "@h [\"1-a\"]-| in(::) gap(2)",
              "@h [\"1-b\"]-| in(::) gap(2)",
              "@v [\"1-b\"]-| in(::) gap(3)"
            ]
      
      parse """
              @grid-template 1 
                "a"
                "a"
                "a"
                "b" gap(10) outer-gap(3); // w/ gaps
            """
          ,
            ccss: [
              "@virtual \"1-a\" \"1-b\"",
              "::[1-md-width] <= (::[width] - 3 - 3) !require"
              "::[1-md-height] <= (::[height] - 3 - 3 - 10 * 3) / 4 !require"
              "\"1-a\"[width] == ::[1-md-width]"
              "\"1-b\"[width] == ::[1-md-width]"
              "\"1-a\"[height] == ::[1-md-height] * 3 + 10 * 2"
              "\"1-b\"[height] == ::[1-md-height]"
            ]
            vfl: [
              "@v [\"1-a\"]-[\"1-b\"] gap(10)",
              "@h |-[\"1-a\"] in(::) gap(3)",
              "@h |-[\"1-b\"] in(::) gap(3)",
              "@v |-[\"1-a\"] in(::) gap(3)",
              "@h [\"1-a\"]-| in(::) gap(3)",
              "@h [\"1-b\"]-| in(::) gap(3)",
              "@v [\"1-b\"]-| in(::) gap(3)"
            ]
            
      
      parse """
              @grid-template 1 
                "aaab"
                h-gap(10) v-gap(10) outer-gap(3) in(::window); // w/ gaps
            """
          ,
            ccss: [
              "@virtual \"1-a\" \"1-b\""              
              "::[1-md-width] <= (::window[width] - 3 - 3 - 10 * 3) / 4 !require"
              "::[1-md-height] <= (::window[height] - 3 - 3) !require"
              "\"1-a\"[width] == ::[1-md-width] * 3 + 10 * 2"
              "\"1-b\"[width] == ::[1-md-width]"
              "\"1-a\"[height] == ::[1-md-height]"
              "\"1-b\"[height] == ::[1-md-height]"
            ]
            vfl: [
              "@h [\"1-a\"]-[\"1-b\"] gap(10)",
              "@h |-[\"1-a\"] in(::window) gap(3)",
              "@v |-[\"1-a\"] in(::window) gap(3)",
              "@v |-[\"1-b\"] in(::window) gap(3)",
              "@h [\"1-b\"]-| in(::window) gap(3)"
              "@v [\"1-a\"]-| in(::window) gap(3)",
              "@v [\"1-b\"]-| in(::window) gap(3)"
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
      
      parse """
              @grid-template dice 
                "1.2"
                ".3."
                "4..";
            """
          ,
            ccss: [
              # alphabetical
              '@virtual "dice-1" "dice-2" "dice-3" "dice-4" "dice-blank-1" "dice-blank-2" "dice-blank-3" "dice-blank-4" "dice-blank-5"' 
              '::[dice-md-width] == ::[width] / 3 !require'
              '::[dice-md-height] == ::[height] / 3 !require'
              "\"dice-1\"[width] == ::[dice-md-width]"
              "\"dice-blank-1\"[width] == ::[dice-md-width]"
              "\"dice-2\"[width] == ::[dice-md-width]"
              "\"dice-blank-2\"[width] == ::[dice-md-width]"
              "\"dice-3\"[width] == ::[dice-md-width]"
              "\"dice-blank-3\"[width] == ::[dice-md-width]"
              "\"dice-4\"[width] == ::[dice-md-width]"
              "\"dice-blank-4\"[width] == ::[dice-md-width]"
              "\"dice-blank-5\"[width] == ::[dice-md-width]"
              "\"dice-1\"[height] == ::[dice-md-height]",
              "\"dice-blank-1\"[height] == ::[dice-md-height]",
              "\"dice-2\"[height] == ::[dice-md-height]",
              "\"dice-blank-2\"[height] == ::[dice-md-height]",
              "\"dice-3\"[height] == ::[dice-md-height]",
              "\"dice-blank-3\"[height] == ::[dice-md-height]",
              "\"dice-4\"[height] == ::[dice-md-height]",
              "\"dice-blank-4\"[height] == ::[dice-md-height]"
              "\"dice-blank-5\"[height] == ::[dice-md-height]"
            ]
            vfl: [
              "@v [\"dice-1\"][\"dice-blank-2\"]"
              "@v [\"dice-blank-2\"][\"dice-4\"]"
              "@v [\"dice-blank-1\"][\"dice-3\"]"
              "@v [\"dice-3\"][\"dice-blank-4\"]"
              "@v [\"dice-2\"][\"dice-blank-3\"]"
              "@v [\"dice-blank-3\"][\"dice-blank-5\"]"
              "@h [\"dice-1\"][\"dice-blank-1\"]"
              "@h [\"dice-blank-1\"][\"dice-2\"]"
              "@h [\"dice-blank-2\"][\"dice-3\"]"
              "@h [\"dice-3\"][\"dice-blank-3\"]"
              "@h [\"dice-4\"][\"dice-blank-4\"]"
              "@h [\"dice-blank-4\"][\"dice-blank-5\"]"
              "@h |[\"dice-1\"] in(::)",
              "@h |[\"dice-blank-2\"] in(::)",
              "@h |[\"dice-4\"] in(::)",
              "@v |[\"dice-1\"] in(::)",
              "@v |[\"dice-blank-1\"] in(::)",
              "@v |[\"dice-2\"] in(::)",
              "@h [\"dice-2\"]| in(::)",
              "@h [\"dice-blank-3\"]| in(::)",
              "@h [\"dice-blank-5\"]| in(::)",
              "@v [\"dice-4\"]| in(::)"
              "@v [\"dice-blank-4\"]| in(::)"
              "@v [\"dice-blank-5\"]| in(::)"
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
  
  
  
    
