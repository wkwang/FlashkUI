package cn.flashk.controls.events
{
	import flash.events.Event;

	public class TreeEvent extends Event
	{
		public static const TREE_NODE_OPEN:String = "treeNodeOpen";
		public static const TREE_NODE_CLOSE:String = "treeNodeClose";
		
		public function TreeEvent(type:String)
		{
			super(type);
		}
	}
}