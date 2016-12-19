path = require 'path'
grammarTest = require 'atom-grammar-test'

describe 'DTML grammar', ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-dtml')

    waitsForPromise ->
      atom.packages.activatePackage('language-coffee-script')

    runs ->
      grammar = atom.grammars.grammarForScopeName('text.dtml.basic')

  it 'parses the grammar', ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe 'text.dtml.basic'

  describe 'meta.scope.outside-tag scope', ->
    it 'tokenizes an empty file', ->
      lines = grammar.tokenizeLines ''
      expect(lines[0][0]).toEqual value: '', scopes: ['text.dtml.basic']

    it 'tokenizes a single < as without freezing', ->
      lines = grammar.tokenizeLines '<'
      expect(lines[0][0]).toEqual value: '<', scopes: ['text.dtml.basic']

      lines = grammar.tokenizeLines ' <'
      expect(lines[0][0]).toEqual value: ' <', scopes: ['text.dtml.basic']

    it 'tokenizes <? without locking up', ->
      lines = grammar.tokenizeLines '<?'
      expect(lines[0][0]).toEqual value: '<?', scopes: ['text.dtml.basic']

    it 'tokenizes >< as dtml without locking up', ->
      lines = grammar.tokenizeLines '><'
      expect(lines[0][0]).toEqual value: '><', scopes: ['text.dtml.basic']

    it 'tokenizes < after tags without locking up', ->
      lines = grammar.tokenizeLines '<span><'
      expect(lines[0][3]).toEqual value: '<', scopes: ['text.dtml.basic']

  describe 'template script tags', ->
    it 'tokenizes the content inside the tag as DTML', ->
      lines = grammar.tokenizeLines '''
        <script id='id' type='text/template'>
          <div>test</div>
        </script>
      '''

      expect(lines[0][0]).toEqual value: '<', scopes: ['text.dtml.basic', 'punctuation.definition.tag.dtml']
      expect(lines[1][0]).toEqual value: '  ', scopes: ['text.dtml.basic', 'text.embedded.dtml']
      expect(lines[1][1]).toEqual value: '<', scopes: ['text.dtml.basic', 'text.embedded.dtml', 'meta.tag.block.any.dtml', 'punctuation.definition.tag.begin.dtml']

  describe 'CoffeeScript script tags', ->
    it 'tokenizes the content inside the tag as CoffeeScript', ->
      lines = grammar.tokenizeLines '''
        <script id='id' type='text/coffeescript'>
          -> console.log 'hi'
        </script>
      '''

      expect(lines[0][0]).toEqual value: '<', scopes: ['text.dtml.basic', 'punctuation.definition.tag.dtml']
      expect(lines[1][0]).toEqual value: '  ', scopes: ['text.dtml.basic', 'source.coffee.embedded.dtml']
      expect(lines[1][1]).toEqual value: '->', scopes: ['text.dtml.basic', 'source.coffee.embedded.dtml', 'storage.type.function.coffee']

  describe 'JavaScript script tags', ->
    beforeEach ->
      waitsForPromise -> atom.packages.activatePackage('language-javascript')

    it 'tokenizes the content inside the tag as JavaScript', ->
      lines = grammar.tokenizeLines '''
        <script id='id' type='text/javascript'>
          var hi = 'hi'
        </script>
      '''

      expect(lines[0][0]).toEqual value: '<', scopes: ['text.dtml.basic', 'punctuation.definition.tag.dtml']

      expect(lines[1][0]).toEqual value: '  ', scopes: ['text.dtml.basic', 'source.js.embedded.dtml']
      expect(lines[1][1]).toEqual value: 'var', scopes: ['text.dtml.basic', 'source.js.embedded.dtml', 'storage.type.var.js']

  describe "comments", ->
    it "tokenizes -- as an error", ->
      {tokens} = grammar.tokenizeLine '<!-- some comment --->'

      expect(tokens[0]).toEqual value: '<!--', scopes: ['text.dtml.basic', 'comment.block.dtml', 'punctuation.definition.comment.dtml']
      expect(tokens[1]).toEqual value: ' some comment -', scopes: ['text.dtml.basic', 'comment.block.dtml']
      expect(tokens[2]).toEqual value: '-->', scopes: ['text.dtml.basic', 'comment.block.dtml', 'punctuation.definition.comment.dtml']

      {tokens} = grammar.tokenizeLine '<!-- -- -->'

      expect(tokens[0]).toEqual value: '<!--', scopes: ['text.dtml.basic', 'comment.block.dtml', 'punctuation.definition.comment.dtml']
      expect(tokens[1]).toEqual value: ' ', scopes: ['text.dtml.basic', 'comment.block.dtml']
      expect(tokens[2]).toEqual value: '--', scopes: ['text.dtml.basic', 'comment.block.dtml', 'invalid.illegal.bad-comments-or-CDATA.dtml']
      expect(tokens[3]).toEqual value: ' ', scopes: ['text.dtml.basic', 'comment.block.dtml']
      expect(tokens[4]).toEqual value: '-->', scopes: ['text.dtml.basic', 'comment.block.dtml', 'punctuation.definition.comment.dtml']

  grammarTest path.join(__dirname, 'fixtures/syntax_test_dtml.dtml')
  grammarTest path.join(__dirname, 'fixtures/syntax_test_dtml_template_fragments.dtml')

  describe "entities", ->
    it "tokenizes & and characters after it", ->
      {tokens} = grammar.tokenizeLine '& &amp; &a'

      expect(tokens[0]).toEqual value: '&', scopes: ['text.dtml.basic', 'invalid.illegal.bad-ampersand.dtml']
      expect(tokens[3]).toEqual value: 'amp', scopes: ['text.dtml.basic', 'constant.character.entity.dtml', 'entity.name.entity.other.dtml']
      expect(tokens[4]).toEqual value: ';', scopes: ['text.dtml.basic', 'constant.character.entity.dtml', 'punctuation.definition.entity.end.dtml']
      expect(tokens[7]).toEqual value: 'a', scopes: ['text.dtml.basic']

  describe "firstLineMatch", ->
    it "recognises DTML5 doctypes", ->
      expect(grammar.firstLineRegex.scanner.findNextMatchSync("<!DOCTYPE dtml>")).not.toBeNull()
      expect(grammar.firstLineRegex.scanner.findNextMatchSync("<!doctype DTML>")).not.toBeNull()

    it "recognises Emacs modelines", ->
      valid = """
        #-*- DTML -*-
        #-*- mode: DTML -*-
        /* -*-dtml-*- */
        // -*- DTML -*-
        /* -*- mode:DTML -*- */
        // -*- font:bar;mode:DTML -*-
        // -*- font:bar;mode:DTML;foo:bar; -*-
        // -*-font:mode;mode:DTML-*-
        // -*- foo:bar mode: dtml bar:baz -*-
        " -*-foo:bar;mode:dtml;bar:foo-*- ";
        " -*-font-mode:foo;mode:dtml;foo-bar:quux-*-"
        "-*-font:x;foo:bar; mode : DTML; bar:foo;foooooo:baaaaar;fo:ba;-*-";
        "-*- font:x;foo : bar ; mode : HtML ; bar : foo ; foooooo:baaaaar;fo:ba-*-";
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        /* --*dtml-*- */
        /* -*-- DTML -*-
        /* -*- -- DTML -*-
        /* -*- HTM -;- -*-
        // -*- xDTML -*-
        // -*- DTML; -*-
        // -*- dtml-stuff -*-
        /* -*- model:dtml -*-
        /* -*- indent-mode:dtml -*-
        // -*- font:mode;dtml -*-
        // -*- HTimL -*-
        // -*- mode: -*- DTML
        // -*- mode: -dtml -*-
        // -*-font:mode;mode:dtml--*-
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises Vim modelines", ->
      valid = """
        vim: se filetype=dtml:
        # vim: se ft=dtml:
        # vim: set ft=DTML:
        # vim: set filetype=XDTML:
        # vim: ft=XDTML
        # vim: syntax=DTML
        # vim: se syntax=xdtml:
        # ex: syntax=DTML
        # vim:ft=dtml
        # vim600: ft=xdtml
        # vim>600: set ft=dtml:
        # vi:noai:sw=3 ts=6 ft=dtml
        # vi::::::::::noai:::::::::::: ft=dtml
        # vim:ts=4:sts=4:sw=4:noexpandtab:ft=dtml
        # vi:: noai : : : : sw   =3 ts   =6 ft  =dtml
        # vim: ts=4: pi sts=4: ft=dtml: noexpandtab: sw=4:
        # vim: ts=4 sts=4: ft=dtml noexpandtab:
        # vim:noexpandtab sts=4 ft=dtml ts=4
        # vim:noexpandtab:ft=dtml
        # vim:ts=4:sts=4 ft=dtml:noexpandtab:\x20
        # vim:noexpandtab titlestring=hi\|there\\\\ ft=dtml ts=4
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        ex: se filetype=dtml:
        _vi: se filetype=DTML:
         vi: se filetype=DTML
        # vim set ft=dtml5
        # vim: soft=dtml
        # vim: clean-syntax=dtml:
        # vim set ft=dtml:
        # vim: setft=DTML:
        # vim: se ft=dtml backupdir=tmp
        # vim: set ft=DTML set cmdheight=1
        # vim:noexpandtab sts:4 ft:DTML ts:4
        # vim:noexpandtab titlestring=hi\\|there\\ ft=DTML ts=4
        # vim:noexpandtab titlestring=hi\\|there\\\\\\ ft=DTML ts=4
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()
