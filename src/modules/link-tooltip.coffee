_               = require('underscore')
ScribeDOM       = require('../dom')
ScribeKeyboard  = require('../keyboard')
ScribePosition  = require('../position')
ScribeRange     = require('../range')


enterEditMode = (url) ->
  url = normalizeUrl(url)
  ScribeDOM.addClass(@tooltip, 'editing')
  @tooltipInput.focus()
  @tooltipInput.value = url

exitEditMode = ->
  if @tooltipLink.innerText != @tooltipInput.value
    @savedRange.formatContents('link', @tooltipInput.value, { source: 'user' })
    @tooltipLink.href = @tooltipInput.value
    ScribeDOM.setText(@tooltipLink, @tooltipInput.value)
    @toolbar.emit(@toolbar.constructor.events.FORMAT, 'link', @tooltipInput.value)
    @editor.setSelection(null, true)
  ScribeDOM.removeClass(@tooltip, 'editing')

hideTooltip = ->
  @tooltip.style.left = '-10000px'

initListeners = ->
  ScribeDOM.addEventListener(@editor.root, 'mouseup', (event) =>
    link = event.target
    while link? and link.tagName != 'DIV' and link.tagName != 'BODY'
      if link.tagName == 'A'
        start = new ScribePosition(@editor, link, 0)
        end = new ScribePosition(@editor, link, ScribeDOM.getText(link).length)
        @savedRange = new ScribeRange(@editor, start, end)
        @tooltipLink.innerText = @tooltipLink.href = link.href
        ScribeDOM.removeClass(@tooltip, 'editing')
        showTooptip.call(this, link.getBoundingClientRect())
        return
      link = link.parentNode
    hideTooltip.call(this)
  )
  ScribeDOM.addEventListener(@button, 'click', =>
    value = null
    range = @editor.getSelection()
    if ScribeDOM.hasClass(@button, 'active')
      value = false
    else
      @savedRange = range
      url = @savedRange.getText()
      if /\w+\.\w+/.test(url)
        value = normalizeUrl(url)
      else
        ScribeDOM.addClass(@tooltip, 'editing')
        showTooptip.call(this, @editor.selection.getDimensions())
        enterEditMode.call(this, url)
    if value?
      range.formatContents('link', value, { source: 'user' })
      @toolbar.emit(@toolbar.constructor.events.FORMAT, 'link', value)
  )
  ScribeDOM.addEventListener(@tooltipChange, 'click', =>
    enterEditMode.call(this, @tooltipLink.innerText)
  )
  ScribeDOM.addEventListener(@tooltipDone, 'click', =>
    exitEditMode.call(this)
  )
  ScribeDOM.addEventListener(@tooltipInput, 'keyup', (event) =>
    exitEditMode.call(this) if event.which == ScribeKeyboard.keys.ENTER
  )

initTooltip = ->
  @tooltip = @button.ownerDocument.createElement('div')
  @tooltip.id = 'link-tooltip'
  @tooltip.innerHTML =
   '<span class="title">Visit URL:</span>
    <a href="#" class="url" target="_blank" href="about:blank"></a>
    <input class="input" type="text">
    <span>&#45;</span>
    <a href="javascript:;" class="change">Change</a>
    <a href="javascript:;" class="done">Done</a>'
  @tooltipLink = @tooltip.querySelector('.url')
  @tooltipInput = @tooltip.querySelector('.input')
  @tooltipChange = @tooltip.querySelector('.change')
  @tooltipDone = @tooltip.querySelector('.done')
  @editor.renderer.addStyles(
    '#link-tooltip': {
      'background-color': '#fff'
      'border': '1px solid #000'
      'left': '-10000px'
      'height': '23px'
      'padding': '5px 10px'
      'position': 'absolute'
      'white-space': 'nowrap'
    }
    '#link-tooltip a': {
      'cursor': 'pointer'
      'text-decoration': 'none'
    }
    '#link-tooltip > a, #link-tooltip > span': {
      'display': 'inline-block'
      'line-height': '23px'
    }
    '#link-tooltip .input'          : { 'display': 'none', 'width': '170px' }
    '#link-tooltip .done'           : { 'display': 'none' }
    '#link-tooltip.editing .input'  : { 'display': 'inline-block' }
    '#link-tooltip.editing .done'   : { 'display': 'inline-block' }
    '#link-tooltip.editing .url'    : { 'display': 'none' }
    '#link-tooltip.editing .change' : { 'display': 'none' }
  )
  @editor.renderer.runWhenLoaded( =>
    _.defer( =>
      @editor.renderer.addContainer(@tooltip)
    )
  )

normalizeUrl = (url) ->
  url = 'http://' + url unless /^https?:\/\//.test(url)
  url = url + '/' unless url.slice(-1) == '/' # Add trailing slash to standardize between browsers
  return url
  
showTooptip = (target, subjectDist = 5) ->
  tooltip = @tooltip.getBoundingClientRect()
  tooltipHeight = tooltip.bottom - tooltip.top
  tooltipWidth = tooltip.right - tooltip.left
  limit = @editor.root.getBoundingClientRect()
  left = Math.max(limit.left, target.left + (target.right-target.left)/2 - tooltipWidth/2)
  if left + tooltipWidth > limit.right and limit.right - tooltipWidth > limit.left
    left = limit.right - tooltipWidth
  top = target.bottom + subjectDist
  if top + tooltipHeight > limit.bottom and target.top - tooltipHeight - subjectDist > limit.top
    top = target.top - tooltipHeight - subjectDist
  @tooltip.style.left = left
  @tooltip.style.top = top + (@tooltip.offsetTop-tooltip.top)


class ScribeLinkTooltip
  constructor: (@button, @toolbar) ->
    @editor = @toolbar.editor
    initTooltip.call(this)
    initListeners.call(this)


module.exports = ScribeLinkTooltip
