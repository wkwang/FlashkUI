package cn.flashk.controls.support
{
	import cn.flashk.controls.List;
	import cn.flashk.controls.interfaces.IListItemRender;
	import cn.flashk.controls.managers.DefaultStyle;
	import cn.flashk.controls.managers.SkinLoader;
	import cn.flashk.controls.managers.SkinManager;
	import cn.flashk.controls.managers.SourceSkinLinkDefine;
	import cn.flashk.controls.managers.StyleManager;
	import cn.flashk.controls.managers.UISet;
	import cn.flashk.controls.skin.SkinThemeColor;
	import cn.flashk.controls.skin.sourceSkin.ListItemSourceSkin;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getDefinitionByName;

	public class ListItemRender extends Sprite implements IListItemRender
	{
		protected var tf:TextFormat;
		
		protected var _data:Object;
		protected var txt:TextField;
		protected var bg:Shape;
		protected var _height:Number;
		protected var _width:Number;
		protected var _list:Object;
		protected var _selected:Boolean = false;
		protected var bp:Bitmap;
		protected var padding:Number;
		protected var _isUseMyselfPadding:Boolean = false;
		protected var skin:ListItemSourceSkin;
		protected var iconDis:DisplayObject;
		protected var _mouseOutAlpha:Number;
		
		public function destory():void
		{
			_list = null;
			txt = null;
			iconDis = null;
			bg = null;
			_data = null;
			bp = null;
		}
		
		public function ListItemRender()
		{
			txt = new TextField();
			bg = new Shape();
			_height = List.defaultItemHeight;
			txt.mouseEnabled = false;
			txt.y = 2;
			txt.x = 20;
			tf = new TextFormat();
			tf.font = DefaultStyle.font;
			tf.color = ColorConversion.transformWebColor(DefaultStyle.textColor);
			this.addEventListener(MouseEvent.MOUSE_OVER,showOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,showOut);
			txt.defaultTextFormat =tf ;
			this.addChild(txt);
			txt.height = _height-2;
			if(SkinManager.isUseDefaultSkin == true){
				this.addChildAt(bg,0);
			}else{
				skin = new ListItemSourceSkin();
				skin.init2(this,{},SkinLoader.getClassFromSkinFile(SourceSkinLinkDefine.LIST_ITEM_BACKGROUND));
				skin.space = 1;
			}
		}
		
		
		public function set index(value:int):void
		{
			if(value%2==0){
				_mouseOutAlpha = StyleManager.listIndex1Alpha;
			}else
			{
				_mouseOutAlpha = StyleManager.listIndex2Alpha;
			}
			if(_selected == false)
			{
				bg.alpha = _mouseOutAlpha;
			}
		}
		
		protected function showOver(event:MouseEvent=null):void
		{
			if(_selected == false){
				bg.alpha = StyleManager.listOverAlpha;
				tf.color = SkinThemeColor.itemMouseOverTextColor;
				txt.setTextFormat(tf);
				if(skin != null){
					skin.showState(1);
				}
			}
		}
		
		public function showSelect(event:MouseEvent=null):void
		{
			bg.alpha = 1;
			tf.color = SkinThemeColor.itemOverTextColor;
			txt.setTextFormat(tf);
			txt.defaultTextFormat =tf ;
			if(skin != null){
				skin.showState(2);
			}
		}
		protected function showOut(event:MouseEvent =null):void
		{
			if(_selected == false){
				bg.alpha = _mouseOutAlpha;
				tf.color = ColorConversion.transformWebColor(DefaultStyle.textColor);
				txt.setTextFormat(tf);
				txt.defaultTextFormat =tf ;
				if(skin != null){
					skin.showState(0);
				}
			}
			
		}
		public function set list(value:List):void{
			_list = value;
		}
		public function set data(value:Object):void{
			_data = value;
			txt.text = _data.label;
			if(_data.icon != null){
				setIcon(_data.icon,List(_list).useIconWidth);
			}else{
				//txt.x = 1;
			}
		}
		public function setIcon(iconRef:Object,isUseMyselfPadding:Boolean = false):void{
			iconDis = null;
			_isUseMyselfPadding = isUseMyselfPadding;
			if(bp == null){
				bp = new Bitmap();
			}
			if(iconRef is String)
			{
				try{
					iconRef = getDefinitionByName(String(iconRef)) as Class;
				}catch(e:Error)
				{
					if(_list && _list.loaderInfo)
					{
						iconRef = _list.loaderInfo.applicationDomain.getDefinition(String(iconRef)) as Class;
					}
				}
			}
			if(iconRef is Class){
				var icon:Object = new iconRef();
				if(icon is BitmapData)
				{
					bp.bitmapData = icon as BitmapData;
				}else
				{
					iconDis = icon as DisplayObject;
				}
			}
			if(iconRef is BitmapData){
				bp.bitmapData = iconRef as BitmapData;
			}
			bp.smoothing = UISet.listIconSmooth;
			this.addChild(bp);
			if(isUseMyselfPadding == false){
				bp.x = Number(_list.getStyleValue("iconPadding"));
			}else{
				bp.x = padding;
				if(iconDis)
				{
					txt.x = bp.x + iconDis.width;
				}else
				{
					txt.x = bp.x + bp.width+2;
				}
			}
			bp.y = int((_height - bp.height)/2);
			if(bp.y<0) bp.y = 0;
			if(iconDis)
			{
				this.addChild(iconDis);
				this.removeChild(bp);
			}
		}
		public function get data():Object{
			return _data;
		}
		public function get itemHeight():Number{
			return _height;
		}
		public function setSize(newWidth:Number, newHeight:Number):void{
			_width = newWidth;
			bg.graphics.clear();
			bg.graphics.beginFill(SkinThemeColor.itemOverColor,1);
			bg.graphics.drawRect(0,0,newWidth,_height);
			
			if(_isUseMyselfPadding == false){
				txt.x = Number(_list.getStyleValue("textPadding"));
			}
			txt.width = _width - txt.x;
			if(_selected == true){
				showSelect();
			}
			if(skin != null){
				skin.setSize(newWidth,newHeight);
			}
			txt.y = int((List.defaultItemHeight-19)/2);
		}
		public function set selected(value:Boolean):void{
			_selected = value;
			if(_selected == true){
				showSelect();
			}else{
				showOut();
			}
		}
		public function get selected():Boolean{
			return _selected;
		}
	}
}