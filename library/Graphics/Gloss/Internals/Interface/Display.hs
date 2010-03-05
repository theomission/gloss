{-# OPTIONS_HADDOCK hide #-}

module Graphics.Gloss.Internals.Interface.Display
	(displayInWindow)
where	
import Graphics.Gloss.Color
import Graphics.Gloss.Picture
import Graphics.Gloss.ViewPort
import Graphics.Gloss.Internals.Render.Picture
import Graphics.Gloss.Internals.Render.ViewPort
import Graphics.Gloss.Internals.Interface.Window
import Graphics.Gloss.Internals.Interface.Common.Exit
import Graphics.Gloss.Internals.Interface.ViewPort.KeyMouse
import Graphics.Gloss.Internals.Interface.ViewPort.Motion
import Graphics.Gloss.Internals.Interface.ViewPort.Reshape
import qualified Graphics.Gloss.Internals.Render.Options			as RO
import qualified Graphics.Gloss.Internals.Interface.ViewPort.ControlState	as VPC
import qualified Graphics.Gloss.Internals.Interface.Callback			as Callback

import Data.IORef
import Control.Concurrent


-- | Open a new window and display the given picture.
--
--   Use the following commands once the window is open:
--
-- 	* Quit - esc-key.
--
--	* Move Viewport - left-click drag, arrow keys.
--
--	* Rotate Viewport - right-click drag, control-left-click drag, or home\/end-keys.
--
--	* Zoom Viewport - mouse wheel, or page up\/down-keys.
--
displayInWindow
	:: String	-- ^ Name of the window.
	-> (Int, Int)	-- ^ Initial size of the window, in pixels.
	-> (Int, Int)	-- ^ Initial position of the window, in pixels.
	-> Color	-- ^ Background color.
	-> Picture	-- ^ The picture to draw.
	-> IO ()

displayInWindow name size pos background picture
 =  do
	viewSR		<- newIORef viewPortInit
	viewControlSR	<- newIORef VPC.stateInit
	renderSR	<- newIORef RO.optionsInit
	
	let renderFun = do
		view	<- readIORef viewSR
		options	<- readIORef renderSR
	 	withViewPort
	 		view
			(renderPicture options view picture)

	let callbacks
	     =	[ Callback.Display renderFun 

		-- Delay the thread for a bit to give the runtime
		--	a chance to switch back to the OS.
		, Callback.Idle	   (threadDelay 1000)

		-- Escape exits the program
		, callback_exit () 
		
		-- Viewport control with mouse
		, callback_viewPort_keyMouse viewSR viewControlSR 
		, callback_viewPort_motion   viewSR viewControlSR 
		, callback_viewPort_reshape ]

	createWindow name size pos background callbacks

