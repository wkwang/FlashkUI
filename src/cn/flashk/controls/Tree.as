package cn.flashk.controls
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import cn.flashk.controls.interfaces.IListItemRender;
	import cn.flashk.controls.managers.StyleManager;
	import cn.flashk.controls.support.SWFDefinition;
	import cn.flashk.controls.support.TreeItemRender;
	import cn.flashk.controls.support.UIComponent;
	

	/**
	 * Tree 组件使用户可以查看排列为可扩展树的层次结构数据。树中的每个项目都可以是叶或分支。叶项目是树中的端点。分支项目可以包含叶或分支项目，也可以为空。 
	 * 
	 * 对于复杂的Tree组合变换，可以对原始XML进行操作，然后调用updateAfterOperateXML()（或直接将XML重新赋值给dataProvider）即可,Tree会自动刷新。
	 * 对于删除Tree子节点，先操作dataProvider的XML使用delete (XML) 运算符 ，然后调用updateAfterOperateXML()
	 *  
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 9.0
	 * 
	 * @see cn.flashk.controls.support.UIComponent
	 * 
	 * @author flashk
	 */
	public class Tree extends List
	{
		
		/**
		 * 设置根项目的可见性。如果 dataProvider 数据包含根节点，并且根节点的设置为 false，则 Tree 控件不会显示根项目。仅显示根项目的后代。
		 */ 
		public var isShowRoot:Boolean = false;
		public var openStates:Array = [];
		private var _rendersCatch:Array = [];

		public function get isParentAutoClickOpen():Boolean
		{
			return _isParentAutoClickOpen;
		}

		/**
		 * 是否有子节点时点击自动展开而不需点击到小箭头 
		 * @param value
		 * 
		 */
		public function set isParentAutoClickOpen(value:Boolean):void
		{
			_isParentAutoClickOpen = value;
		}

		/**
		 * 自定义图标的获取函数，如果在XML中定义了自定义节点图标，渲染器会向这个函数发送图标名称，函数应该返回根据这个名称创建或引用的BitmapData实例，默认的函数是cn.flashk.controls.support.SWFDefinition.getDefinitionBitmapDataByName。如果图标需要从其它地方获得，可以定义自己的获取函数
		 * 
		 * @see cn.flashk.controls.support.SWFDefinition
		 */ 
		public var iconGetFunction:Function = SWFDefinition.getDefinitionBitmapDataByName;
		public var addedIndex:int;
		private var _floderIcon:BitmapData;
		private var _nodeIcon:BitmapData;
		private var _closedIcon:BitmapData;
		private var _openedIcon:BitmapData;
		private var xmlAll:XML;
		private var xml:XML;
		private var _isParentAutoClickOpen:Boolean = false;
		private var _isFirstData:Boolean = true;
		private var _dict:Object;
		private var _dict2:Dictionary;
		private var _alinIndex:int=0;
		
		public override function destroy():void
		{
			super.destroy();
			xmlAll = null;
			xml = null;
			_dict = null;
			_dict2 = null;
			openStates = null;
			_rendersCatch = null;
		}
		
		public function Tree()
		{
			super();
			
			_dict = new Dictionary();
			_compoWidth = 300;
			_compoHeight = 23*8;
			labelField = "@label";
			iconField = "@icon";
			_isRemoveDestory = false;
			_snapNum = StyleManager.defaultTreeSnapNum;
			_itemRender = TreeItemRender;
			_allowMultipleSelection = true;
			styleSet["padding"] = 10;
			styleSet["textPadding"] = 20;
			setSize(_compoWidth, _compoHeight);
			scrollBar.setTarget(items,false,_compoWidth,_compoHeight-2);
		}
		
		public function pushRenderInCatch(render:*,key:String):void
		{
			_dict2[render] = key;
//			for each (var obj:Array in _rendersCatch) 
//			{ 
//				if(obj[0] == render)
//				{
//					obj[1] = key;
//					return;
//				}
//			}
//			_rendersCatch.push([render,key]);
		}
		
		public function findInRenderCatch(key:String):*
		{
//			for each (var obj:Array in _rendersCatch) 
//			{ 
//					if(obj[1] == key)
//					{
//						return obj[0] 
//					}
//			}
//			return null;
			return _dict[key];
		}
		
		public function resetDict():void
		{
			var oldDict:Object = _dict;
			_dict = new Object();
			for(var obj:Object in _dict2)
			{
				_dict[_dict2[obj]] = obj;
			}
			for(var j:String in oldDict)
			{
				_dict[j] = oldDict[j];
			}
		}
		
		/**
		 * 设置Tree的数据源， 它应该是个XML
		 */ 
		override public function set dataProvider(value:Object):void
		{
			if((value is XML) == false)
			{
				return;
			}
			_alinIndex = 0;
			var index:int = _selectedIndex;
			var len:int = length;
			var scrollPos:Number = scrollBar.scrollPosition;
			_dataProvider = value;
			removeAll();
			var isNewXML:Boolean = xmlAll == value;
			if(_isFirstData == false && isNewXML == true)
			{
				_isNeedAlign = false;
			}
			_dict2 = new Dictionary();
			xmlAll = _dataProvider as XML;
			XML.ignoreComments = true;
			initListByXML();
			if(_isFirstData == false && isNewXML == true)
			{
				resetState();
				if(index+length-len>addedIndex)
				{
					selectedIndex =index+ length-len;
					scrollBar.scrollToPosition((selectedIndex-3)*List.defaultItemHeight);
				}else
				{
					selectedIndex =index;
					scrollBar.scrollToPosition(scrollPos);
				}
			}
			_isFirstData = false;
			setTimeout(resetNeedAlgian,40);
			resetDict();
		}
		
		private function resetNeedAlgian():void
		{
			_isNeedAlign = true;
		}
		
		public function resetState():void
		{
			resetOneNodeState(xmlAll);
			alignItems(items);
		}
		
		private function resetOneNodeState(node:XML):void
		{
			var nodeChildren:Object = node.children();
			var len:int = nodeChildren.length();
			for(var i:int=0;i<len;i++)
			{
				var childNode:Object = nodeChildren[i];
				var childLen:int = childNode.toString() =="" ? 0 :1;
				if(childLen>0 && getOpenState(childNode) == true)
				{
					openItem(childNode,false);
				}
				if(childLen > 0)
				{
					resetOneNodeState(childNode as XML);
				}
			}
		}
		
		/**
		 * 设置树中文件夹（含有有子项节点）的图标
		 */ 
		public function set floderIcon(bd:BitmapData):void
		{
			_floderIcon = bd;
		}
		
		public function get floderIcon():BitmapData
		{
			return _floderIcon;
		}
		
		/**
		 * 设置树中没有子项节点的图标
		 */ 
		public function set nodeIcon(bd:BitmapData):void
		{
			_nodeIcon = bd;
		}
		
		public function get nodeIcon():BitmapData
		{
			return _nodeIcon;
		}
		
		/**
		 * 设置树中没有展开的图标前面的小箭头
		 */ 
		public function set closedIcon(bd:BitmapData):void
		{
			_closedIcon = bd;
		}
		
		public function get closedIcon():BitmapData
		{
			return _closedIcon;
		}
		
		/**
		 * 设置树中已经展开的图标前面的小箭头
		 */ 
		public function set openedIcon(bd:BitmapData):void
		{
			_openedIcon = bd;
		}
		
		public function get openedIcon():BitmapData
		{
			return _openedIcon;
		}
		
		/**
		 * 打开指定的节点
		 */ 
		public function openItem(item:Object,animate:Boolean = false,nodes:Object=null):void
		{
			var len:int = items.numChildren;
			for(var i:int=0;i<len;i++)
			{
				TreeItemRender(items.getChildAt(i)).checkOpenNode(item,nodes);
			}
		}
		
		/**
		 * 关闭指定的节点
		 */ 
		public function closeItem(item:Object,animate:Boolean = false):void
		{
			for(var i:int=0;i<items.numChildren;i++)
			{
				TreeItemRender(items.getChildAt(i)).checkCloseNode(item);
			}
		}
		
		/**
		 * 打开或关闭指定的节点下所有的节点，如果不传递参数，则打开关闭整个树
		 */ 
		public function expandChildrenOf(item:Object=null, isOpen:Boolean=true):void
		{
			for(var i:int=0;i<items.numChildren;i++)
			{
				TreeItemRender(items.getChildAt(i)).expandChildrenOf(item,isOpen);
			}
			if(item== null)
			{
				selectedIndex = 0;
			}
		}
		
		/**
		 * 如果指定的项目分支处于打开状态（显示其子项），则返回 true。
		 */ 
		public function isItemOpen(item:Object):Boolean
		{
			for(var i:int=0;i<items.numChildren;i++)
			{
					if(TreeItemRender(items.getChildAt(i)).data == item)
					{
						return TreeItemRender(items.getChildAt(i)).opened;
					}
			}
			return false;
		}
		
		public function setOpenState(item:Object,isOpen:Boolean):void
		{
			var len:int = openStates.length;
			for(var i:int=0;i<len;i++)
			{
				if(openStates[i][0] == item)
				{
					openStates[i][1] = isOpen;
					return;
				}
			}
			openStates.push([item,isOpen]);
		}
		
		public function getOpenState(item:Object):Boolean
		{
			var len:int = openStates.length;
			for(var i:int=0;i<len;i++)
			{
				if(openStates[i][0] == item)
				{
					return openStates[i][1];
				}
			}
			return false;
		}
		
		/**
		 * 将一个XML插入到指定节点之后 
		 * @param item
		 * @param afterNode
		 * 
		 */
		public function addItemChildAfter(item:XML,afterNode:XML):void
		{
			var par:XML = afterNode.parent();
			par.insertChildAfter(afterNode,item);
			_isNeedAddUpdate = true;
			UIComponent.stage.addEventListener(Event.RENDER,updateTree);
			UIComponent.stage.invalidate();
		}
		
		/**
		 * 将一个XML插入到指定节点之前 
		 * @param item
		 * @param beforeNode
		 * 
		 */
		public function addItemChildBefore(item:XML,beforeNode:XML):void
		{
			var par:XML = beforeNode.parent();
			par.insertChildBefore(beforeNode,item);
			_isNeedAddUpdate = true;
			UIComponent.stage.addEventListener(Event.RENDER,updateTree);
			UIComponent.stage.invalidate();
		}
		
		/**
		 * 将一个XML元素加入到指定节点的子项目中 
		 * @param item
		 * @param parentNode
		 * 
		 */
		public function addItemChildIn(item:XML,parentNode:XML):void
		{
			parentNode.appendChild(item);
			_isNeedAddUpdate = true;
			UIComponent.stage.addEventListener(Event.RENDER,updateTree);
			UIComponent.stage.invalidate();
		}
		
		private function updateTree(event:Event):void
		{
			if(_isNeedAddUpdate == true)
			{
				dataProvider = _dataProvider;
			}
			_isNeedAddUpdate = false;
		}
		
		/**
		 * 当对复杂的树原始XML进行组合变换或删除操作完成后，立即刷新树
		 * 
		 */
		public function updateAfterOperateXML():void
		{
			dataProvider = _dataProvider;
		}
		
		private function initListByXML():void
		{
			if(isShowRoot == false)
			{
				xml = xmlAll[0];
			}else{
				xml = xmlAll;
			}
			var item:IListItemRender;
			var itemWidth:Number = _compoWidth;
			if(scrollBar.visible == true)
			{
				itemWidth =scrollBar.x;
			}
			for(var i:int=0;i<xml.children().length();i++)
			{
				item = new _itemRender();
				item.list = this;
				item.data = xml.children()[i];
				item.setSize(itemWidth,0);
				items.addChild(item as DisplayObject);
				Object(item).idStr = "0:_"+i;
				InteractiveObject(item).addEventListener(MouseEvent.CLICK,itemClick);
				InteractiveObject(item).addEventListener(MouseEvent.ROLL_OVER,itemMouseOver);
				InteractiveObject(item).addEventListener(MouseEvent.ROLL_OUT,itemMouseOut);
			}
			if(_isFirstData == true)
			{
				alignItems(items);
			}
			UIComponent.stage.addEventListener(Event.RENDER,alignItemOneFrame);
			UIComponent.stage.invalidate();
		}
		
		public function addItemRenderAt(render:IListItemRender,index:uint):void
		{
			var dis:DisplayObject = DisplayObject(render);
			items.addChildAt(dis,index);
			dis.addEventListener(MouseEvent.CLICK,itemClick);
			dis.addEventListener(MouseEvent.ROLL_OVER,itemMouseOver);
			dis.addEventListener(MouseEvent.ROLL_OUT,itemMouseOut);
			UIComponent.stage.addEventListener(Event.RENDER,alignItemOneFrame);
			UIComponent.stage.invalidate();
		}
		
		private function alignItemOneFrame(event:Event):void
		{
			if(_isNeedAlign == false)
			{
				_isNeedAlign = true;
				return;
			}
			alignItems(items);
		}
		
		public function removeItemRenderAt(render:IListItemRender):void{
			
			items.removeChild(render as DisplayObject);
						UIComponent.stage.addEventListener(Event.RENDER,alignItemOneFrame);
						UIComponent.stage.invalidate();
		}
		
		public function alignItems(itemsContainer:DisplayObjectContainer=null):void
		{
			if(itemsContainer == null) itemsContainer = items;
			if(itemsContainer.numChildren == 0)
			{
				return;
			}
			itemsContainer.getChildAt(0).y = 0;
			IListItemRender(itemsContainer.getChildAt(0)).index = 0;
			var item:IListItemRender;
			var followItem:IListItemRender;
			if(itemsContainer.numChildren==1)
			{
				return;
			}
			for(var i:int=1;i<itemsContainer.numChildren;i++)
			{
				item = itemsContainer.getChildAt(i) as IListItemRender;
				followItem = itemsContainer.getChildAt(i-1) as IListItemRender;
				DisplayObject(item).y = DisplayObject(followItem).y + followItem.itemHeight;
				IListItemRender(item).index = i;
			}
			var maxHe:Number = DisplayObject(item).y  + item.itemHeight;
			if(maxHe > _compoHeight)
			{
				scrollBar.setTarget(items,false,_compoWidth-17,_compoHeight-items.y-1);
				scrollBar.updateSize(item.itemHeight*items.numChildren);
				scrollBar.visible = true;
			}else
			{
				scrollBar.setTarget(items,false,_compoWidth,_compoHeight-items.y-1);
				scrollBar.updateSize(1);
				scrollBar.visible = false;
			}
			scrollBar.updateSize(maxHe,true);
			scrollBar.updateScrollBarPostion();
			scrollBar.snapNum = _snapNum;
			scrollBar.arrowClickStep = List.defaultItemHeight;
			if(scrollBar.visible != scrollBarLastVisible || 2>1){
				updateSkin();
			}
			scrollBarLastVisible = scrollBar.visible;
		}
		
	}
}