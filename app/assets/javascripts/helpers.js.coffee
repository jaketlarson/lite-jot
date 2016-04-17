## This file contains global, generic helpers

# Array Remove - By John Resig (MIT Licensed)
Array::remove = (from, to) ->
  rest = @slice((to or from) + 1 or @length)
  @length = if from < 0 then @length + from else from
  @push.apply this, rest

window.randomKey = =>
  build_key = ""
  possibilities = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890"

  for i in [0..50]
    build_key += possibilities.charAt(Math.floor(Math.random() * possibilities.length))

  return build_key;

# escapeHtml/unescapeHtml: http://shebang.brandonmintern.com/foolproof-html-escaping-in-javascript/
window.escapeHtml = (str) ->
  div = document.createElement('div')
  div.appendChild document.createTextNode(str)
  div.innerHTML
window.unescapeHtml = (escapedStr) ->
  div = document.createElement('div')
  div.innerHTML = escapedStr
  child = div.childNodes[0]
  if child then child.nodeValue else ''

$ ->
  # hasScrollBar: http://stackoverflow.com/questions/4814398/how-can-i-check-if-a-scrollbar-is-visible
  $.fn.hasScrollBar = ->
    @get(0).scrollHeight > @height()

  # Reduces the size of text in the element to fit the parent.
  # http://stackoverflow.com/a/34366375/3179806
  $.fn.reduceTextSize = (options) ->

    checkWidth = (em) ->
      $em = $(em)
      oldPosition = $em.css('position')
      $em.css 'position', 'absolute'
      width = $em.width()
      $em.css 'position', oldPosition
      width

    options = $.extend({ minFontSize: 1 }, options)
    @each ->
      $this = $(this)
      $parent = $this.parent()
      prevFontSize = undefined

      while checkWidth($this) > $parent.width() - parseInt($parent.css('paddingLeft')) - parseInt($parent.css('paddingRight'))
        currentFontSize = parseInt($this.css('font-size').replace('px', ''))
        # Stop looping if min font size reached, or font size did not change last iteration.
        if isNaN(currentFontSize) or currentFontSize <= options.minFontSize or prevFontSize and prevFontSize == currentFontSize
          break
        prevFontSize = currentFontSize
        $this.css 'font-size', currentFontSize-1 + 'px'
      return
