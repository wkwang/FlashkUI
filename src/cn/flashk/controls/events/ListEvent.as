package cn.flashk.controls.events
{
	import flash.events.Event;

	public class ListEvent extends Event
	{
		public static  const CHANGE:String = "change";
		
		public function ListEvent(type:String)
		{
			super(type);
		}
	}
}