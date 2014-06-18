{
  namespace,
  utils,
  ui: {progress},
  templates: {tpl},
  jQuery: $,
  crop: {CropWidget},
  locale: {t}
} = uploadcare

namespace 'uploadcare.widget.tabs', (ns) ->
  class ns.PreviewTab extends ns.BasePreviewTab

    constructor: ->
      super

      $.each @dialogApi.fileColl.get(), (i, file) =>
        @__setFile file

      @dialogApi.fileColl.onAdd.add @__setFile

      @widget = null

    __setFile: (@file) =>
      ifCur = (fn) =>
        =>
          if file == @file
            fn.apply(null, arguments)

      @file.progress ifCur utils.once (info) =>
        @__setState 'unknown', {file: info.incompleteFileInfo}

      @file.done ifCur (file) =>
        state = if file.isImage then 'image' else 'regular'
        @__setState state, {file}

      @file.fail ifCur (error, file) =>
        @__setState 'error', {error, file}

    element: (name) ->
      @container.find('@uploadcare-dialog-preview-' + name)

    # error
    # unknown
    # image
    # regular
    __setState: (state, data) ->
      @container.empty().append tpl("tab-preview-#{state}", data)

      if state is 'unknown' and @settings.crop
        @element('done').hide()
      if state is 'image'
        @initImage(data.file)

    initImage: (info) ->
      img = @element('image')
      done = @element('done')
      imgSize = [info.originalImageInfo.width,
                 info.originalImageInfo.height]

      if @settings.crop
        @element('title').text t('dialog.tabs.preview.crop.title')
        done.addClass('uploadcare-disabled-el')
        done.text t('dialog.tabs.preview.crop.done')

        @populateCropSizes()

        img.on 'error', =>
          @file = null
          @__setState 'error', error: 'loadImage'

      startCrop = =>
        @element('crop-sizes').css('visibility', 'visible')
        done.removeClass('uploadcare-disabled-el')

        @widget = new CropWidget img, imgSize, @settings.crop[0]
        @widget.setSelectionFromModifiers(info.cdnUrlModifiers)

        done.click =>
          opts = @widget.getSelectionWithModifiers()
          @dialogApi.fileColl.replace @file, @file.then (info) =>
            info.cdnUrlModifiers = opts.modifiers
            info.cdnUrl = "#{info.originalUrl}#{opts.modifiers or ''}"
            info.crop = opts.crop
            info

      # crop widget can't get container size when container hidden
      # (dialog hidden) so we need timer here
      utils.defer =>
        parentSize = [img.parent().width(), img.parent().height() or 600]
        widgetSize = utils.fitSize(imgSize, parentSize)
        img.css width: widgetSize[0], height: widgetSize[1], maxHeight: 'none'

        if @settings.crop
          utils.imageLoader(img.attr('src')).done startCrop

    populateCropSizes: ->
      if @settings.crop.length <= 1
        return

      @element('root').addClass('uploadcare-dialog-preview---with-sizes')

      control = @element('crop-sizes').show()
      template = control.children()
      currentClass = 'uploadcare-crop-size--current'

      $.each @settings.crop, (i, crop) =>
        prefered = crop.preferedSize
        if prefered
          gcd = utils.gcd(prefered[0], prefered[1])
          caption = "#{prefered[0] / gcd}:#{prefered[1] / gcd}"
        else
          caption = t('dialog.tabs.preview.crop.free')

        item = template.clone().appendTo(control)
        item
          .attr('data-caption', caption)
          .on 'click', (e) =>
            if @widget
              @widget.setCrop(crop)
              control.find('>*').removeClass(currentClass)
              item.addClass(currentClass)
        if prefered
          size = utils.fitSize(prefered, [40, 40], true)
          item.children()
            .css
              width: Math.max 20, size[0]
              height: Math.max 12, size[1]
      template.remove()
      control.find('>*').eq(0).addClass(currentClass)
