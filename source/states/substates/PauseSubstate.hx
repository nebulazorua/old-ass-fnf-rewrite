package states.substates;

import flixel.FlxSubState;
import input.Controls;

class PauseSubstate extends FlxSubState
{
	function actionChanged(action:String, keyCode:Int, state:ActionState)
	{
		switch (action)
		{
			case 'confirm':
				if (state == DOWN)
					close();
			default:
		}
	}

	public function new()
	{
		super();
	}

	override function create()
	{
		Controls.onActionChanged.add(actionChanged);
		super.create();
	}

	override function destroy()
	{
		Controls.onActionChanged.remove(actionChanged);
		super.destroy();
	}
}
