
-- Originally taken from: http://github.com/vicfryzel/xmonad-config

import GetHostName

import System.IO
import System.Exit
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
import XMonad.Hooks.Minimize
import XMonad.Hooks.DebugKeyEvents
import XMonad.ManageHook
import XMonad.Prompt
import XMonad.Prompt.Window
import XMonad.Prompt.Ssh
import XMonad.Actions.CycleWS
import XMonad.Actions.GridSelect
import XMonad.Actions.DynamicWorkspaces
import XMonad.Actions.CopyWindow
import XMonad.Actions.SpawnOn
-- import XMonad.Actions.UpdatePointer 
import qualified XMonad.Actions.FlexibleResize as Flex
-- does not work with xK1..xK_0 mappings :(
--  import qualified XMonad.Actions.DynamicWorkspaceOrder as DO 
import XMonad.Layout.NoBorders
import XMonad.Layout.FixedColumn
import XMonad.Layout.Spiral
-- import XMonad.Layout.Tabbed
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.Minimize
import XMonad.Layout.SimpleDecoration
import XMonad.Layout.GridVariants
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Util.WorkspaceCompare
import XMonad.Util.NamedScratchpad

import qualified XMonad.StackSet    as W
import qualified Data.Map           as M

-- WORKAROUND C-c hanging prompt
myXPConfig_nC       =  defaultXPConfig { 
                       promptKeymap = M.fromList [((controlMask,xK_c), quit)] `M.union` promptKeymap defaultXPConfig
                       {- , autoComplete = Just 500000 -}
               }
myXPConfig          =  myXPConfig_nC { 
                       --  promptKeymap = M.fromList [((controlMask,xK_c), quit)] `M.union` promptKeymap defaultXPConfig ,
                       autoComplete = Just 300000
               }


-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
-- myTerminal       = "sakura"  
--  myTerminal      = "gnome-terminal"
myTerminal _        = "urxvtc"


myScratchpads = [
   -- run htop in xterm, find it by title, use default floating window placement
       NS "htop" "urxvtc -e htop" (title =? "htop") manageNotes ,
       NS "shell" "urxvtc -T shell" (title =? "shell") manageNotes ,
       NS "alsamixer" "urxvtc -e alsamixer" (title =? "alsamixer") manageNotes,

   -- run stardict, find it by class name, place it in the floating window    j
   -- 1/6 of screen width from the left, 1/6 of screen height
   -- from the top, 2/3 of screen width by 2/3 of screen height
       --  NS "stardict" "stardict" (className =? "Stardict")
           --  (customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3)) ,
   -- run gvim, find by role, don't float with nonFloating
       NS "notes" spawnNotes findNotes manageNotes
   ]
   where
       role = stringProperty "WM_WINDOW_ROLE"
       spawnNotes = "gvim --role notes +VimwikiMakeDiaryNote"
       findNotes = role =? "notes"
       manageNotes = customFloating $ W.RationalRect l t w h
           where
               l = 0.35
               t = 0.05
               w = 0.65
               h = 0.85

-- Width of the window border in pixels.
--
myBorderWidth   = 1

-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
--  myModMask       = mod1Mask 
myModMask       = mod4Mask

-- The mask for the numlock key. Numlock status is "masked" from the
-- current modifier status, so the keybindings will work with numlock on or
-- off. You may need to change this on some systems.
--
-- You can find the numlock modifier by running "xmodmap" and looking for a
-- modifier with Num_Lock bound to it:
--
-- > $ xmodmap | grep Num
-- > mod2       Num_Lock (0x4d)
--
-- Set numlockMask = 0 if you don't have a numlock key, or want to treat
-- numlock status separately.
--
myNumlockMask   = mod2Mask

-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]
--
--  myWorkspaces    = ["1:code","2:pdf1","3:pdf2","4:web","5:vserver","6","7","8","9"]
myWorkspaces    = [ "1", "2" ]
myExtendedWorkspaces :: String -> [String]
myExtendedWorkspaces "lark" = [ "NSP", "c", "cP", "music", "quassel", "stream", "root", "web" ]
myExtendedWorkspaces "phaelon" = [ "NSP", "music", "quassel", "root", "web" ]
myExtendedWorkspaces "nukular" = myExtendedWorkspaces "phaelon"
myExtendedWorkspaces "nurikum" = [ "NSP", "c", "cP", "stream", "root", "web" ]
myExtendedWorkspaces "jovis" = [ "NSP", "c", "cP", "quassel", "talk", "talkP", "root", "web" ]
myExtendedWorkspaces _  = ["NSP"]

-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor     = "#7c7c7c"
{- myFocusedBorderColor = "#ffb6b0" -}
myFocusedBorderColor    = "#ff0000"

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here
--

myKeys hostname conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $

   -- launch a terminal
   [ ((modMask .|. shiftMask,      xK_Return   ), spawnHere $ XMonad.terminal conf)

   -- lock screensaver
   , ((modMask .|. controlMask,    xK_l        ), lockSpawner hostname) 

   -- launch dmenu
   --      , ((modMask,                    xK_semicolon), spawnHere "exe=`dmenu_path | dmenu` && eval \"exec $exe\"")
   , ((modMask,                    xK_m),  spawnHere "gmrun")

   -- launch gmrun
   -- , ((modMask .|. shiftMask,       xK_p        ), spawnHere "eval \"exec ~/bin/mydmenu\"") 

   -- launch gvim
   , ((modMask ,                   xK_g        ), spawnHere "gvim")

   -- clipboard management
   -- from primary to clipboard
   , ((modMask ,                   xK_y        ), spawnHere "lolictrl -spc")
   -- from clipboard to primary 
   , ((modMask .|. shiftMask,      xK_y        ), spawnHere "lolictrl -scp")

   -- launch gvim
   , ((modMask ,                   xK_g        ), spawn "gvim")

   -- take screenshot
   , ((modMask .|. controlMask,    xK_p        ), spawnHere "import `date +screen_%F_%H-%M.png`")

   -- close focused window 
   , ((modMask .|. shiftMask,      xK_c        ), kill)

    -- Rotate through the available layout algorithms
   , ((modMask,                    xK_space    ), sendMessage NextLayout)

   --  Reset the layouts on the current workspace to default
   , ((modMask .|. shiftMask,      xK_space    ), setLayout $ XMonad.layoutHook conf)

   -- Resize viewed windows to the correct size
   , ((modMask,                    xK_n        ), refresh)

   -- Move focus to the next window
   , ((modMask,                    xK_Tab      ), windows W.focusDown)

   -- Move focus to the next window
   , ((modMask,                    xK_j        ), windows W.focusDown)

   -- Move focus to the previous window
   , ((modMask,                    xK_k        ), windows W.focusUp)

   -- Move focus to the master window
   -- , ((modMask,                 xK_m        ), windows W.focusMaster)

   -- Swap the focused window and the master window
   , ((modMask,                    xK_Return   ), windows W.swapMaster)

   -- Swap the focused window with the next window
   , ((modMask .|. shiftMask,      xK_j        ), windows W.swapDown)

   -- Swap the focused window with the previous window
   , ((modMask .|. shiftMask,      xK_k        ), windows W.swapUp )

   -- Shrink the master area
   , ((modMask,                    xK_comma    ), sendMessage Shrink)

   -- Expand the master area
   , ((modMask,                    xK_period   ), sendMessage Expand)

   -- Push window back into tiling
   , ((modMask,                    xK_t        ), withFocused $ windows . W.sink)

   -- Increment the number of windows in the master area
   , ((modMask .|. shiftMask,      xK_period   ), sendMessage (IncMasterN 1))

   -- Deincrement the number of windows in the master area
   , ((modMask .|. shiftMask,      xK_comma    ), sendMessage (IncMasterN (-1)))

   -- Toggle fullscreen
   , ((modMask,                    xK_p        ), sendMessage $ Toggle FULL)

   -- toggle the status bar gap TODO, update this binding with avoidStruts,
   , ((modMask,                    xK_n        ), sendMessage ToggleStruts )

   -- Minimize windows
   , ((modMask,                    xK_u        ), withFocused minimizeWindow )
   , ((modMask .|. shiftMask,      xK_u        ), sendMessage RestoreNextMinimizedWin)

   -- Quit xmonad
   , ((modMask .|. shiftMask,      xK_r        ), io (exitWith ExitSuccess))

   -- Restart xmonad
   , ((modMask,                    xK_r        ), restart "xmonad" True) 
   ] ++
   
   -- Prompts
   ------------------------------
   -- Switch to window
   [ 
   ((modMask,                      xK_o        ), windowPromptGoto myXPConfig )
   -- SSH prompt
   --, (( modMask,                 xK_s        ), sshPrompt myXPConfig)
   -- Does not really work as expected, put on hold
   ] ++

   -- Scratch Pads
   ------------------------------
   [
     ((modMask,                      xK_slash        ), namedScratchpadAction myScratchpads "notes" ),
     ((modMask .|. shiftMask,        xK_slash        ), namedScratchpadAction myScratchpads "htop" ),
     ((modMask,                      xK_apostrophe   ), namedScratchpadAction myScratchpads "shell" ),
     ((modMask .|. shiftMask,        xK_apostrophe   ), namedScratchpadAction myScratchpads "alsamixer" )
   ]++

   -- Actions
   ------------------------------
   -- Gridselect
   [ ((modMask,                    xK_i        ), goToSelected defaultGSConfig)
   -- Cycle workspaces With RotView
   -- , ((modMask,                 xK_l        ), moveTo Next AnyWS)
   , ((modMask,                    xK_l        ), moveTo Next hiddenNonIgnoredWS)
   --  , ((modMask,                    xK_l        ), moveTo Next NonEmptyWS) 
   -- , ((modMask,                 xK_h        ), moveTo Prev AnyWS)
   , ((modMask,                    xK_h        ), moveTo Prev hiddenNonIgnoredWS)
   --  , ((modMask,                    xK_h        ), moveTo Prev NonEmptyWS) 
   -- , ((modMask .|. shiftMask,       xK_l        ), shiftTo Next AnyWS)
   , ((modMask .|. shiftMask,      xK_l        ), shiftTo Next hiddenNonIgnoredWS)
   --  , ((modMask,                    xK_l        ), shiftTo Next NonEmptyWS) 
   -- , ((modMask .|. shiftMask,       xK_h        ), shiftTo Prev AnyWS)
   , ((modMask .|. shiftMask,      xK_h        ), shiftTo Prev hiddenNonIgnoredWS)
   {- , ((modMask,                 xK_h        ), shiftTo Prev NonEmptyWS) -}

   , ((modMask,                    xK_a        ), toggleWS )
   ] ++
   --
   -- Add and delete new worksspaces dynamically
   --
   [
     ((modMask .|. shiftMask,      xK_n        ), removeWorkspace)
   , ((modMask,                    xK_semicolon), selectWorkspace myXPConfig)
   -- control modifier disables auto completion
   , ((modMask .|. controlMask,    xK_semicolon), selectWorkspace myXPConfig_nC)
   , ((modMask .|. shiftMask,      xK_semicolon), withWorkspace myXPConfig (windows . W.shift))
   , ((modMask .|. shiftMask .|. controlMask,      xK_semicolon), withWorkspace myXPConfig_nC (windows . W.shift))
   --  , ((modMask .|. shiftMask,      xK_y        ), withWorkspace myXPConfig (windows . copy))
   , ((modMask .|. shiftMask,      xK_m        ), renameWorkspace myXPConfig_nC)
   ] ++

   --
   -- mod-[1..9], Switch to workspace N mod-shift-[1..9], Move client to
   -- workspace N
   --
   --      [((m .|. modMask, k), windows $ f i) | (i, k) <- zip (XMonad.workspaces
   --      conf) [xK_1 .. xK_9] , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
   --      ++
   -- mod-[1..0] Switch to workspace N
   -- zip (zip (repeat modMask) [xK_F1..xK_F12]) (map (withNthWorkspace W.greedyView) [0..])

   -- Start at 1 instead of 0 because we have the NSP workspace as first
   zip (zip (repeat modMask) [xK_1..xK_9]) (map (withNthWorkspaceFiltered W.greedyView) [0..])
   ++
   -- mod-shift-[F1..F12] Move client to workspace N
   zip (zip (repeat (modMask .|. shiftMask)) [xK_1..xK_9]) (map (withNthWorkspaceFiltered W.shift) [0..])
   ++
   -- mod-control-shift-[F1..F12] Copy client to workspace N
   -- zip (zip (repeat (controlMask .|. shiftMask)) [xK_1..xK_9]) (map (withNthWorkspace copy) [1..])
   -- ++

   --
   -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
   -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
   -- changed to q,w,e because then r stands for the reloading it does
   --
   [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
   | (key, sc) <- zip (displayOrder hostname) [0..], (f, m) <- [(W.view, 0),
   (W.shift, shiftMask)]]
   ++ 
   -- Swap screens
   [
       ((modMask, xK_s),  swapNextScreen )
   ]
   --
   -- move focus between screens (Not needed anymore because code above works)
   -- [
         -- ((modMask .|. controlMask, xK_k),  prevScreen)
       -- , ((modMask .|. controlMask, xK_j),  nextScreen)
       -- , ((modMask .|. controlMask, xK_l),  shiftNextScreen)
       -- , ((modMask .|. controlMask, xK_h),  shiftPrevScreen) 
   -- ]
   ++
   -- Music controller
   [
         ((modMask, xK_F10), spawn "playerctl prev")
       , ((modMask, xK_F11), spawn "playerctl next")
       , ((modMask, xK_F12), spawn "playerctl play-pause")
   ]
   where
       lockSpawner "lark" = spawn "slock"
       lockSpawner "phaelon" = spawn "/bin/sh ~/git/dotfiles_desktop/scripts/go_standby.sh"
       lockSpawner "jovis" = spawn "slock"
       lockSpawner _ = spawn "xscreensaver-command -lock"

       -- displayOrder "lark" = [xK_w, xK_q, xK_e]
       displayOrder _ = [xK_q, xK_w, xK_e]


ignoredWorkspaces = ["NSP"]
-- Apply an action to the window stack, while ignoring certain workspaces
withNthWorkspaceFiltered :: (String -> WindowSet -> WindowSet) -> Int -> X ()
withNthWorkspaceFiltered job wnum = do
  sort <- getSortByIndex
  ws <- gets (filter (\s -> not(s `elem` ignoredWorkspaces)) . map W.tag . sort . W.workspaces . windowset)
  case drop wnum ws of
    (w:_) -> windows $ job w
    [] -> return ()

hiddenNonIgnoredWS :: WSType
hiddenNonIgnoredWS = WSIs getWShiddenNonIgnored
  where
    getWShiddenNonIgnored :: X (WindowSpace -> Bool)
    getWShiddenNonIgnored = do
      hs <- gets (filter_ignored . map W.tag . W.hidden . windowset)
      return (\w -> W.tag w `elem` hs)
    filter_ignored = filter (\t -> not (t `elem` ignoredWorkspaces))

    

------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $

   -- mod-button1, Set the window to floating mode and move by dragging
   [ ((modMask, button1), (\w -> focus w >> mouseMoveWindow w))

   -- mod-button2, Raise the window to the top of the stack
   , ((modMask, button2), (\w -> focus w >> windows W.swapMaster))

   -- mod-button3, Set the window to floating mode and resize by dragging
   , ((modMask, button3), (\w -> focus w >> Flex.mouseResizeWindow w))

   -- you may also bind events to the mouse scroll wheel (button4 and button5)
   ]

------------------------------------------------------------------------
-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--
myTabConfig = defaultTheme {  activeBorderColor = "#7C7C7C"
                           , activeTextColor = "#CEFFAC"
                           , activeColor = "#000000"
                           , inactiveBorderColor = "#7C7C7C"
                           , inactiveTextColor = "#EEEEEE"
                           , inactiveColor = "#000000" }
                           
-- myLayout = avoidStruts $ minimize (mkToggle ( NOBORDERS ?? FULL ?? EOT ) $ tiled ||| oddtiled ||| Mirror tiled ||| tabbed shrinkText myTabConfig ||| noBorders Full ||| spiral (6/7))
-- Tabbed layout causes segfault with toggle - RANDOMLY, avoid until known to be fixed
myLayout hostname = avoidStruts $ minimize (mkToggle ( NOBORDERS ?? FULL ?? EOT ) $
   tiled ||| Grid (screenRatio hostname) ||| noBorders streamwatching ||| Mirror tiled ||| noBorders Full ||| spiral (6/7)) ||| oddtiled 
 where
   screenRatio "juno" = 16/9
   screenRatio _ = 16/10

   oddRatio "phaelon" = 1 - 400 / 1440
   oddRatio _ = 1 - 550 / 1920

   -- default tiling algorithm partitions the screen into two panes
   tiled       = Tall nmaster delta ratio
   
   -- Another tiling algorithm where the master pane is larger
   oddtiled    = Tall nmaster delta $ oddRatio hostname

   streamwatching = Tall nmaster delta ( 1280 / 1920 )

   -- The default number of windows in the master pane
   nmaster     = 1

   -- Default proportion of screen occupied by master pane
   ratio       = 1/2

   -- Percent of screen to increment by when resizing panes
   delta       = 3/100

------------------------------------------------------------------------
-- Window rules:

-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook = manageDocks
   <+> manageSpawn
   <+> namedScratchpadManageHook myScratchpads
   <+> composeAll
   [ className =? "MPlayer"            --> doFloat
   , className =? "Smplayer"           --> doFloat
   , className =? "Psx.real"           --> doFloat
   , className =? "Gimp"               --> doFloat
   , className =? "Galculator"         --> doFloat
   , resource  =? "Komodo_find2"       --> doFloat
   , resource  =? "compose"            --> doFloat
   , className =? "Terminal"           --> doShift "1:code"
   , className =? "Gedit"              --> doShift "1:code"
   , className =? "Emacs"              --> doShift "1:code"
   , className =? "Komodo Edit"        --> doShift "1:code"
   , className =? "Emacs"              --> doShift "1:code"
   , className =? "Firefox"            --> doShift "web"
   , className =? "chromium"           --> doShift "web"
   , className =? "Thunderbird-bin"    --> doShift "3:msg"
   , className =? "Pidgin"             --> doShift "3:msg"
   , className =? "VirtualBox"         --> doShift "4:vm"
   , className =? "banshee-1"          --> doShift "5:media"
   , className =? "Ktorrent"           --> doShift "5:media"
   , className =? "Xchat"              --> doShift "5:media"
   , className =? "quasselclient"      --> doShift "quassel"
   , title =? "CS188 Pacman"       --> doShift "ai"
   , resource  =? "desktop_window"     --> doIgnore
   , resource  =? "kdesktop"           --> doIgnore 
   , resource  =? "xfce4-notifyd"      --> doIgnore 
   -- , className  =? "Vlc"                --> doShift "stream"
   -- , title =? "fd://0 - VLC media player" --> doShift "stream"
   ]

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False


------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'DynamicLog' extension for examples.
--
-- To emulate dwm's status bar
--
-- > logHook = dynamicLogDzen
--

------------------------------------------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
--  myStartupHook = return ()
addExtendedWorkspaces hostname = foldl1 (<+>) $ map addHiddenWorkspace $ myExtendedWorkspaces hostname

myStartupHook hostname = setWMName "LG3D"
   <+> addExtendedWorkspaces hostname

-- Minimize windows hook (to restore from taskbar)
myHandleEventHook =
   minimizeEventHook
   --  <+> debugKeyEvents

myLogHookConfig = xmobarPP {
       ppTitle = xmobarColor "#FFB6B0" "" . shorten 100
       --  , ppCurrent = xmobarColor "#CEFFAC" "" 
       , ppCurrent = xmobarColor "#0CC6DA" ""
       , ppHidden = ppHidden xmobarPP . noScratchPad
       , ppHiddenNoWindows = xmobarColor "#777777" "" . noScratchPad
       , ppSep = "   "
       --  , ppSort = DO.getSortByOrder
   }  
   where
       noScratchPad ws = if ws == "NSP" then "" else ws
       

--  myTrayer = "killall trayer; trayer --edge top --align left --margin 1770 --width 150 --widthtype pixel --height 16 --SetDockType true --expand false --padding 1 --tint 0x000000 --transparent true --alpha 0"
-- myTrayer = "killall trayer; trayer --edge top --align left --margin 1340 --width 100 --widthtype pixel --height 16 --padding 1 --tint 0x000000 --transparent true --alpha 0"
myTrayer hostname = "killall trayer; trayer \
   \--edge top \
   \--align left \
   \--margin " ++ (trayMargin hostname) ++ " \
   \--width " ++ (trayWidth hostname) ++ " \
   \--widthtype pixel \
   \--height 16 \
   \--padding 1 \
   \--tint 0x000000 \
   \--transparent true \
   \--alpha 0 \
   \--expand false \
   \--SetDockType  true"
   where
       trayWidth "nurikum" = "150"
       trayWidth "jovis" = "50"
       trayWidth _ = "100"

       trayMargin "nurikum" = "1700"
       trayMargin "phaelon" = "1340"
       trayMargin "jovis" = "1230"
       trayMargin _ = "1820"
myXmobar = "/usr/bin/xmobar ~/.xmonad/xmobar"

------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
--
main = do
   hostname <- getHostName
   xmproc <- spawnPipe myXmobar
   trayer <- spawnPipe $ myTrayer hostname
   xmonad $ (defaults hostname) {
       logHook =   (dynamicLogWithPP $ myLogHookConfig{
                   ppOutput = hPutStrLn xmproc
       })
       -- >> updatePointer (Relative 0.99 0.99)
       --  , manageHook = manageDocks <+> manageSpawn <+> myManageHook
       --  , startupHook = setWMName "LG3D" 
       -- , startupHook = myStartupHook
   }

-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will 
-- use the defaults defined in xmonad/XMonad/Config.hs
-- 
-- No need to modify this.
--
defaults hostname =
   defaultConfig {
     -- simple stuff
       terminal            = myTerminal hostname,
       focusFollowsMouse   = myFocusFollowsMouse,
       borderWidth         = myBorderWidth,
       modMask             = myModMask,
       --  numlockMask         = myNumlockMask,
       workspaces          = myWorkspaces,
       normalBorderColor   = myNormalBorderColor,
       focusedBorderColor  = myFocusedBorderColor,

     -- key bindings
       keys                = myKeys hostname,
       mouseBindings       = myMouseBindings,

     -- hooks, layouts
       layoutHook          = smartBorders $ myLayout hostname,
       manageHook          = myManageHook,
       startupHook         = myStartupHook hostname,
       handleEventHook     = myHandleEventHook
   }


-- vim: ft=haskell
