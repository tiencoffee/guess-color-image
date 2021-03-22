App =
	oninit: !->
		@colors = []
		@color = void
		@selColor = void
		@title = ''
		@img = null
		@score = 0
		@highScore = +localStorage.guessColorImage_highScore or 0
		@isNewHighScore = no
		@w = 0
		@audio =
			tap: new Audio \https://freesound.org/data/previews/262/262958_4932087-lq.mp3
			exact: new Audio \https://freesound.org/data/previews/174/174027_3242494-lq.mp3
			lose: new Audio \https://freesound.org/data/previews/370/370209_1954916-lq.mp3
		@nextImg!

	class: (...classes) ->
		res = []
		for cls in classes
			if Array.isArray cls
				res.push @class ...cls
			else if cls instanceof Object
				for k, v of cls
					res.push k if v
			else if cls?
				res.push cls
		res * " "

	style: (...styles) ->
		res = {}
		for style in styles
			if Array.isArray style
				style = @style ...style
			if style instanceof Object
				for k, val of style
					res[k] = val
					res[k] += \px if not cssUnitless[k] and +val
		res

	nextImg: ->
		id = _.random 210000 367250
		@img = new Image
		try
			@img.src = await (await fetch "https://guess-color-image.vercel.app/api/svg?id=#id")text!
			@img.onload = !~>
				el = document.createElement \canvas
				el.width = 1
				el.height = 1
				ctx = el.getContext \2d
				ctx.imageSmoothingEnabled = no
				ctx.drawImage @img, 0 0 1 1
				[r, g, b] = ctx.getImageData 0 0 1 1 .data
				if r and g and b
					@color = "rgb(#r,#g,#b)"
					colors = [@color]
					while colors.length < 4
						r = _.random 255
						g = _.random 255
						b = _.random 255
						color = "rgb(#r,#g,#b)"
						unless colors.includes color
							colors.push color
					@w = 180
					@colors = _.shuffle colors
					@selColor = void
					@title = 'Đâu là hình ảnh trên khi độ phân giải còn 1px? 🧐'
					m.redraw.sync!
					canvas.width = @w
					canvas.height = @w
					canvas.style.imageRendering = ''
					canvas.style.transform = ''
					canvas.style.background = ''
					canvas.style.filter = ''
					if @score >= 10
						canvas.style.filter = 'grayscale(.9)'
					ctx = canvas.getContext \2d
					ctx.imageSmoothingEnabled = yes
					ctx.drawImage @img, 0 0 @w, @w
				else
					@nextImg!
			@img.onerror = !~>
				@nextImg!
		catch
			@nextImg!

	onclickColor: (color, event) !->
		{x, y, width, height} = event.target.getBoundingClientRect!
		@audio.tap.load!
		@audio.tap.play!
		markEl = document.createElement \div
		appEl.appendChild markEl
		markEl.className = \mark
		anime do
			targets: markEl
			left: [x + \px, x - 12 + \px]
			top: [y + \px, y - 12 + \px]
			width: [width + \px, width + 24 + \px]
			height: [height + \px, height + 24 + \px]
			borderRadius: [\24px \24px]
			opacity:
				value: [1 0]
				easing: \easeInQuart
			duration: 500
			easing: \easeOutQuart
			complete: !~>
				markEl.remove!
		anime do
			targets: event.target
			scale: [0.9 1]
			duration: 500
			easing: \easeOutQuart
		unless @selColor
			@selColor = color
			canvas.style.imageRendering = \pixelated
			anime do
				targets: @
				w: 1
				duration: 1000
				easing: \linear
				update: (anim) !~>
					canvas.width = @w
					canvas.height = @w
					canvas.style.transform = "scale(#{180 / @w})"
					if canvas.style.filter.includes \grayscale
						canvas.style.filter = "grayscale(#{0.9 * (1 - anim.progress / 100)})"
					ctx = canvas.getContext \2d
					ctx.imageSmoothingEnabled = no
					ctx.drawImage @img, 0 0 @w, @w
				complete: !~>
					canvas.style.background = @color
					@title = ''
					if color is @color
						@score++
						if @highScore > 4 and not @isNewHighScore
							if @score is @highScore
								@title = 'Bạn sắp đạt kỷ lục mới! 😧'
							else if @score > @highScore
								@title = 'Vượt kỷ lục rồi! 😱'
						unless @title
							titles =
								'Tuyệt! 🎉'
								'Đúng luôn haha! 😆'
								'Giỏi vãi! 😱'
								'Đỉnh thật! 😮'
								'Ghê đấy! 😌'
								'Xuất sắc! 👏'
								'Khá phết nhờ! 😃'
								'Siêu! 😋'
								'Giỏi thế ai chơi! 🥺'
							@title = _.sample titles
						if @score > @highScore
							@highScore = @score
							localStorage.guessColorImage_highScore = @highScore
							@isNewHighScore = yes
						@audio.exact.play!
					else
						if @score is 0
							titles =
								'Chưa gì đã sai rồi! 😂'
								'0 điểm về chỗ! 🤣'
						unless titles
							titles =
								'Sai rồi! 😥'
								'Thử lại nhé! 🙁'
								'Nhầm rồi bạn ơi! 😵'
								'Ôi không! 😭'
						@title = _.sample titles
						@score = 0
						@isNewHighScore = no
						@audio.lose.play!
					@nextImg!
					m.redraw!

	view: ->
		m \.p-4.h-100,
			style:
				maxWidth: \400px
				margin: \auto
				backgroundImage: 'linear-gradient(180deg,#ffb6ce,#fff)'
			if @color
				m \.h-100,
					m \.row.w-100,
						style:
							height: \10%
						m \.col,
							"Điểm: #@score"
						m \.col.text-right,
							"Điểm cao: #@highScore"
					m \h3.m-0.text-center,
						style:
							height: \20%
						@title
					m \.row.center.middle,
						style:
							height: \40%
						m \canvas#canvas,
							style:
								borderRadius: \.1px
					m \.w-100.row.gap-x-4.between.middle,
						style:
							height: \30%
						@colors.map (color) ~>
							m \.col.ratio-1x1.color,
								style:
									maxWidth: \160px
									borderRadius: \16px
									background: color
								onclick: (event) !~>
									@onclickColor color, event

m.mount appEl, App
