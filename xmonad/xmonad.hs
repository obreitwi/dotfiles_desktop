-- Originally taken from: http://github.com/vicfryzel/xmonad-config

import GetHostname

import qualified Control.Monad.Trans.Reader as R
import Control.Monad (when)

import Data.List (sortOn)

import System.IO
import System.Exit
import XMonad
import XMonad.Hooks.DynamicBars
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
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
import XMonad.Actions.Minimize
import XMonad.Actions.SpawnOn
-- import XMonad.Actions.UpdatePointer
import qualified XMonad.Actions.FlexibleResize as Flex
-- does not work with xK1..xK_0 mappings :(
--  import qualified XMonad.Actions.DynamicWorkspaceOrder as DO
import XMonad.Layout.NoBorders
import XMonad.Layout.FixedColumn
import XMonad.Layout.Spiral
import XMonad.Layout.Tabbed
import XMonad.Layout.LayoutScreens
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.Minimize
import XMonad.Layout.SimpleDecoration
import XMonad.Layout.GridVariants
import XMonad.Layout.IndependentScreens(countScreens, withScreens)
import XMonad.Layout.ThreeColumns
import XMonad.Layout.TwoPane
import XMonad.Util.Run(spawnPipe, safeSpawn, unsafeSpawn)
import XMonad.Util.SpawnOnce(spawnOnce)
import XMonad.Util.EZConfig(additionalKeysP)
import XMonad.Util.WorkspaceCompare
import XMonad.Util.NamedScratchpad
-- import XMonad.Config.Xfce

-- Fuzzy matching
import XMonad.Prompt.FuzzyMatch

import qualified XMonad.StackSet    as W
import qualified Data.List          as L
import qualified Data.Map           as M

data MyConfig = MyConfig
  { hostname :: String
  , numScreens :: Int
  }

setHostname :: String -> MyConfig -> MyConfig
setHostname newHostname oldConfig = oldConfig { hostname = newHostname }

-- WORKAROUND C-c hanging prompt
myXPConfigBase = def
               { promptKeymap = M.fromList [((controlMask,xK_c), quit)] `M.union` promptKeymap def
               , font = "xft:Envy Code R:style=Regular:size=8"
               }
myXPConfig_nC = myXPConfigBase
               { searchPredicate = fuzzyMatch
               , sorter          = fuzzySort
               }
myXPConfig = myXPConfigBase { autoComplete = Just 300000 }
              --  promptKeymap = M.fromList [((controlMask,xK_c), quit)] `M.union` promptKeymap def ,


-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
getTerminal :: R.Reader MyConfig String
getTerminal = do
    host <- R.asks hostname
    return $ go host
  where
    go "mucku" = "alacritty"
    go "abed" = "alacritty"
    go "mimir" = "alacritty"
    go _ = "urxvtc"

getAltTerminal :: R.Reader MyConfig String
getAltTerminal = do
    host <- R.asks hostname
    return $ go host
  where
    go "mucku" = "urxvtc"
    go _ = "alacritty"

getTermTitleArg :: R.Reader MyConfig String
getTermTitleArg = getTerminal >>= (return . go)
  where
    go "urxvtc" = "-T"
    go "alacritty" = "-t"
    go _ = "-T"

getScratchpads = do
  term <- getTerminal
  termTitleArg <- getTermTitleArg
  let termTitle = term ++ " " ++ termTitleArg ++ " "
  return
    [  NS "alsamixer" (termTitle ++ "alsamixer -e alsamixer") (title =? "alsamixer") defaultOverlay
    ,  NS "bashtop" (termTitle ++ "bashtop -e bashtop") (title =? "bashtop") defaultOverlay
    ,  NS "bpytop" (termTitle ++ "BpyTOP -e bpytop") (title =? "BpyTOP") defaultOverlay
    ,  NS "htop" (termTitle ++ "htop -e htop") (title =? "htop") defaultOverlay
    ,  NS "shell" (termTitle ++ "shell") (title =? "shell") defaultOverlay
    ,  NS "ipython" (termTitle ++ "ipython -e ipython") (title =? "ipython") defaultOverlay
    ,  NS "ptpython" (termTitle ++ "\"Python REPL (ptpython)\" -e ptpython") (title =? "Python REPL (ptpython)") defaultOverlay
    ,  NS "nvim-ghost" (termTitle ++ "nvim-ghost -e nvim  +GhostStart") (title =? "nvim-ghost") defaultOverlay
    ,  NS "neovide-ghost" "neovide +GhostStart '+set titlestring=neovide-ghost' '+set title'" (title =? "neovide-ghost") defaultOverlay
       -- run stardict, find it by class name, place it in the floating window
       -- 1/6 of screen width from the left, 1/6 of screen height
       -- from the top, 2/3 of screen width by 2/3 of screen height
       --  NS "stardict" "stardict" (className =? "Stardict")
       --  (customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3)) ,
    -- run gvim, find by role, don't float with nonFloating
    ,  NS "notes" (spawnNotes termTitle) findNotes defaultOverlay
    ,  NS "notes-neovide" spawnNotes_neovide findNotes defaultOverlay
    ,  NS "volumecontrol" "pavucontrol" (title =? "Volume Control") defaultOverlay
    ]
  where
       -- unfortunately neovide is not yet running as expected (does not allow floating and resizing) -> keep nvim in terminal for now
       -- role = stringProperty "WM_WINDOW_ROLE"
       spawnNotes termTitle = "cd ~/.vimwiki && " ++ termTitle ++ "notes -e nvim +VimwikiMakeDiaryNote"
       spawnNotes_neovide = "cd ~/.vimwiki && neovide '+set titlestring=notes' '+set title' +VimwikiMakeDiaryNote '+set columns=" ++ (show numCols) ++ "'"
       -- findNotes = role =? "notes"
       findNotes = title =? "notes"
       defaultOverlay = customFloating $ W.RationalRect l t w h
       l = 0.35
       t = 0.05
       w = 1.0 - l
       h = 0.85
       numCols = 206
       -- TODO: get width from env
       -- numCols = flip (-) 2 $ floor $ 1920.0 * w / 7.0

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
getWorkspaces :: R.Reader MyConfig [String]
getWorkspaces = R.asks hostname >>= (return . go)
  where
    go "abed" = three
    go "mimir" = three
    go _ = two
    three = [ "1", "2", "3"]
    two = [ "1", "2" ]

getExtendedWorkspaces :: R.Reader MyConfig [String]
getExtendedWorkspaces = do
    host <- R.asks hostname
    -- ns <- R.asks numScreens
    -- return $ withScreens (S ns) $ extws host
    return $ [ "NSP" ] ++ extws host ++ [ "z" ]
  where
    extws "abed" = [ "games", "music", "stream", "root", "web", "z" ]
    extws "mimir" = [ "chat", "fdc", "music", "root", "web", "z" ]
    extws "gordon" = [ "root", "web" ]
    extws "jovis" = [ "c", "cP", "quassel", "talk", "talkP", "root", "web" ]
    extws "lark" = [ "music", "stream", "root", "web" ]
    extws "mucku" = [ "chat", "games", "music", "voice", "voice", "root", "tv", "web", "z" ]
    extws "nukular" = extws "phaelon"
    extws "nurikum" = [ "c", "cP", "music", "stream", "root", "web" ]
    extws "phaeloff" = extws "phaelon"
    extws "phaelon" = [ "music", "root", "web" ]
    extws _  = []

-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor     = "#7c7c7c"
{- myFocusedBorderColor = "#ffb6b0" -}
myFocusedBorderColor    = "#ff0000"

------------------------------------------------------------------------
-- Helper functions and programs used in key bindings
--

getSpawnerProg :: R.Reader MyConfig String
getSpawnerProg = do
    host <- R.asks hostname
    return $ prg host
  where
     prg _ = "rofi -show run"
     -- prg _ = "gmrun"


getProxyString = return " --proxy-server='socks5://localhost:8080' --host-resolver-rules='MAP * 0.0.0.0' --proxy-bypass-list='127.0.0.1;localhost;*.kip.uni-heidelberg'"

browser :: R.Reader MyConfig String
browser = do
    host <- R.asks hostname
    myProxyString <- getProxyString
    return $ brs host myProxyString
  where
    brs "lark" mps = "chromium" ++ mps
    brs "gordon" _ = "google-chrome"
    brs "phaeloff" _ = "google-chrome-stable"
    brs "mucku" _ = "firefox"
    brs "abed" _ = "firefox"
    brs "mimir" _ = "firefox"
    brs _ _ = "chromium"
-- browser "lark" = "chromium --process-per-site --proxy-server='socks5://localhost:8080' --host-resolver-rules='MAP * 0.0.0.0' --proxy-bypass-list='127.0.0.1;localhost;*.kip.uni-heidelberg'"

browserProxy = do
  browserNoProxy <- browser
  myProxyString <- getProxyString
  return $ browserNoProxy ++ myProxyString

-- exitXmonad "gordon" = spawn "xfce4-session-logout"
exitXmonad = return $ io (exitWith ExitSuccess)

lockSpawner = do
    host <- R.asks hostname
    if host == "phaelon" then
      return $ spawn "/bin/sh ~/git/dotfiles_desktop/scripts/go_standby.sh"
    else
     return $ spawn "slock"
-- lockSpawner _ = spawn "xscreensaver-command -lock"

-- displayOrder "nurikum" = [xK_w, xK_q, xK_e]
getDisplayOrder = do
    host <- R.asks hostname
    numScreens <- R.asks numScreens
    return $ hlp host numScreens
  where
    -- hlp "abed" 2 = [xK_w, xK_e] -- same as if there were three monitors
    -- hlp "abed" _ = [xK_w, xK_q, xK_e]
    -- hlp "mimir" 3 = [xK_w, xK_e, xK_q]
    hlp _ _ = [xK_q, xK_w, xK_e, xK_r]


toWorkspaceTag :: String -> X ()
toWorkspaceTag tag = do
  s <- gets windowset
  when (W.tagMember tag s) $
    if W.currentTag s /= tag then
      windows $ W.greedyView tag
    else
      toggleWSnoNSP

getPythonPrompt :: R.Reader MyConfig String
getPythonPrompt = R.asks hostname >>= go
  where
    go "mucku" = return "ptpython"
    go "mimir" = return "ptpython"
    go _       = return "ipython"

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here
--
getKeys :: R.Reader MyConfig (XConfig Layout -> M.Map (KeyMask, KeySym) (X ()))
getKeys = do
  myBrowserProxy <- browserProxy
  myDisplayOrder <- getDisplayOrder
  myExitXmonad <- exitXmonad
  myLockSpawner <- lockSpawner
  myScratchpads <- getScratchpads
  mySpawnerProg <- getSpawnerProg
  myPythonPrompt <- getPythonPrompt
  myAltTerm <- getAltTerminal
  return $ \ (conf@(XConfig {XMonad.modMask = modMask})) ->
    M.fromList $
    -- launch a terminal
    [ ((modMask .|. shiftMask,      xK_Return   ), spawnHere $ XMonad.terminal conf)
    , ((modMask .|. controlMask,    xK_Return   ), spawnHere myAltTerm)
    , ((modMask .|. mod1Mask,       xK_Return   ), spawnHere "kitty")

    -- lock screensaver
    , ((modMask .|. controlMask,    xK_l        ), myLockSpawner)

    -- launch dmenu
    --      , ((modMask,                    xK_semicolon), spawnHere "exe=`dmenu_path | dmenu` && eval \"exec $exe\"")
    , ((modMask,                    xK_m),       spawnHere mySpawnerProg)

    -- refresh montiros
    , ((modMask,                    xK_x),       spawnHere "nemo")

    -- launch gmrun
    -- , ((modMask .|. shiftMask,       xK_p        ), spawnHere "eval \"exec ~/bin/mydmenu\"")

    -- launch emoji picker
    , ((modMask .|. controlMask,    xK_i        ), spawnHere "rofimoji -a copy")

    -- launch pavucontrol
    , ((modMask ,                   xK_c        ), namedScratchpadAction myScratchpads "volumecontrol")

    -- launch browser
    , ((modMask ,                   xK_b        ), spawn "open-default-browser")
    -- launch browser with proxy enabled
    , ((modMask .|. shiftMask,      xK_b        ), spawn myBrowserProxy)

    -- clipboard management
    -- copy selection -> clipboard
    , ((modMask .|. controlMask,    xK_k        ), spawn "sh -c 'xclip -o | xclip -i -selection clipboard'")

    -- take screenshot
    -- , ((modMask .|. controlMask,    xK_p        ), spawnHere "import `date +screens/screen_%F_%H-%M.png`")
    , ((modMask .|. controlMask,                  xK_p        ), spawnHere "maim -u -m 10 -s |  xclip -selection clipboard -t image/png")
    , ((modMask .|. controlMask .|. shiftMask,    xK_p        ), spawnHere "maim -u -s $(date +screens/screen_%F_%H-%M.png)")

    -- close focused window
    , ((modMask .|. shiftMask,      xK_c        ), kill)

     -- Rotate through the available layout algorithms
    , ((modMask,                    xK_space    ), sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default
    , ((modMask .|. shiftMask,      xK_space    ), setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modMask,                    xK_v        ), spawnHere "nemo $HOME")

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
    , ((modMask .|. shiftMask,      xK_comma   ), sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ((modMask .|. shiftMask,      xK_period    ), sendMessage (IncMasterN (-1)))

    -- Toggle fullscreen
    , ((modMask,                    xK_p        ), sendMessage $ Toggle NBFULL )

    -- toggle the status bar gap TODO, update this binding with avoidStruts,
    , ((modMask,                    xK_n        ), sendMessage ToggleStruts )

    -- Minimize windows
    , ((modMask,                    xK_u        ), withFocused minimizeWindow )
    , ((modMask .|. shiftMask,      xK_u        ), withLastMinimized maximizeWindow)

    -- Quit xmonad
    , ((modMask .|. shiftMask,      xK_F4       ), myExitXmonad)

    -- Restart xmonad
    , ((modMask,                    xK_F4       ), restart "xmonad" True)
    ] ++

    -- Prompts
    ------------------------------
    -- Switch to window
    [
    ((modMask,                      xK_o        ), windowPrompt myXPConfig Goto allWindows )
    -- SSH prompt
    --, (( modMask,                 xK_s        ), sshPrompt myXPConfig)
    -- Does not really work as expected, put on hold
    ] ++

    -- Scratch Pads
    ------------------------------
    [
      ((modMask,                      xK_slash        ), namedScratchpadAction myScratchpads "notes" ),
      ((modMask .|. controlMask,      xK_slash        ), namedScratchpadAction myScratchpads "notes-neovide" ),
      ((modMask .|. shiftMask,        xK_slash        ), namedScratchpadAction myScratchpads "htop" ),
      ((modMask,                      xK_apostrophe   ), namedScratchpadAction myScratchpads "shell" ),
      ((modMask .|. shiftMask,        xK_apostrophe   ), namedScratchpadAction myScratchpads "alsamixer" ),
      ((modMask,                      xK_backslash    ), namedScratchpadAction myScratchpads "bpytop" ),
      ((modMask .|. shiftMask,        xK_backslash    ), namedScratchpadAction myScratchpads "bashtop" ),
      ((modMask,                      xK_g            ), namedScratchpadAction myScratchpads "nvim-ghost" ),
      ((modMask .|. shiftMask,        xK_p            ), namedScratchpadAction myScratchpads myPythonPrompt )
    ]++

    -- Actions
    ------------------------------
    -- Gridselect
    [ ((modMask,                    xK_i        ), goToSelected def)
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

    , ((modMask,                    xK_a        ), toggleWSnoNSP )
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

    -- special workspaces
    [
      ((modMask,                    xK_z        ), toWorkspaceTag "z")
    ] ++

    -- ultra-wide settings
    [ ((modMask .|. controlMask,    xK_q        ), rescreen )
    , ((modMask .|. controlMask,    xK_w        ), layoutScreens 2 (TwoPane 0.5 0.5) )
    , ((modMask .|. controlMask,    xK_s        ), layoutScreens 2 (Tall 1 (3/100) (1/2)))
    , ((modMask .|. controlMask,    xK_x        ), layoutScreens 2 (Tall 1 (3/100) (2/3) ))
    , ((modMask .|. controlMask,    xK_e        ), layoutScreens 3 (ThreeColMid 1 (3/100) (1/2)))
    , ((modMask .|. controlMask,    xK_d        ), layoutScreens 3 (ThreeColMid 1 (3/100) (1/3)))
    , ((modMask .|. controlMask,    xK_r        ), layoutScreens 3 (Tall 1 (3/100) (1/2 + 13/100)))
    , ((modMask .|. controlMask,    xK_f        ), layoutScreens 3 (Tall 1 (3/100) (2/3)))
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
    -- [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
    [((m .|. modMask, key), applyToWSinScreen sc f)
      | (key, sc) <- zip myDisplayOrder [0..]
      , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
    ]
    ++
    -- Swap screens
    [ ((modMask, xK_s),  swapNextScreen )
    , ((modMask, xK_d),  swapPrevScreen )
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
    [
      -- launch browsers (not working)
       {-
        -   ((modMask, xK_F7),
        -       spawnOn "chat" (browser hostname)
        -     >> spawnOn "stream" (browser hostname)
        -     >> spawnOn "web" (browser hostname))
        - , ((modMask .|. shiftMask, xK_F7),
        -       spawnOn "chat" (browserProxy hostname ++ " web.whatsapp.com https://brainscales-r.kip.uni-heidelberg.de:6443/visions/")
        -     >> spawnOn "stream" (browserProxy hostname)
        -     >> spawnOn "web" (browserProxy hostname))
        -}
    ]
    ++
    -- Debug
    [   ((modMask .|. controlMask, xK_F8), debugStuff)
    ]
    ++
    [
      -- launch password helper
      ((modMask, xK_F8),    spawn "rofi -modi 1pass:rofi-1pass -show 1pass")
    ]
    ++
    -- Toggle Microphone in Zoom
    [   ((modMask, xK_F9),  spawn "zoom-toggle-audio")
    ]
    ++
    -- Music controller
    [
        ((modMask, xK_F10), spawn "myplayerctl prev")
      , ((modMask, xK_F11), spawn "myplayerctl next")
      , ((modMask, xK_F12), spawn "myplayerctl play-pause")
    ]
    ++
    -- Reset monitor configuration to use all available monitors
    [
        ((modMask .|. controlMask, xK_F10), spawn "autorandr -c")
      , ((modMask .|. controlMask, xK_F11), spawn "autorandr -l default")
      , ((modMask .|. controlMask, xK_F12), spawn "rofi-autorandr")
    ]

-- apply action current workspace in screen
applyToWSinScreen :: Int -> (WorkspaceId -> WindowSet -> WindowSet) -> X ()
applyToWSinScreen screen action = do
    wsScreens <- withWindowSet $ return . sortOn W.screen  . W.screens
    numPhysicalScreens <- countScreens
    -- liftIO $ logToTmpFile $ "Num physical screens: " ++ show numPhysicalScreens ++
      -- " Num virtual screens: " ++ show (length wsScreens)
    -- liftIO $ mapM_ (\(i, s) -> logToTmpFile ("Screen #" ++ show i ++ ": " ++ show s)) $ zip [0..] wsScreens
    let numScreens = length wsScreens
    -- TODO: Add check for one physical screen
        screenIdx = case () of
            _ | False && numScreens == 3 && numPhysicalScreens == 1 -> case screen of
              0 -> 1
              1 -> 0
              x -> x
            otherwise -> screen
        targetWS = W.tag . W.workspace $ wsScreens !! screenIdx
    -- currentWS <- withWindowSet $ return . W.currentTag
    -- liftIO $ logToTmpFile $ "Target: " ++ show targetWS
    -- liftIO $ logToTmpFile $ "Current: " ++ show currentWS
    -- debugCurrentWindowSet "Before transition: "
    -- currentStack <- withWindowSet $ return
    -- let newStack = action targetWS currentStack
    -- liftIO $ logToTmpFile $ "Dry-applying action: " ++ show newStack
    windows $ action targetWS
    -- debugCurrentWindowSet "After transition: "

debugCurrentWindowSet :: String -> X ()
debugCurrentWindowSet note = do
  ws <- withWindowSet $ return
  liftIO $ logToTmpFile $ note ++ show ws

getAdditionalKeys = do
   return $ \ conf -> additionalKeysP conf
     [
     --   ("<XF86MonBrightnessDown>", spawn "backlight -10%")
     -- , ("<XF86MonBrightnessUp>", spawn "backlight +10%")
     ]

ignoredWorkspaces = ["NSP"]
toggleWSnoNSP = toggleWS' ignoredWorkspaces

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
myTabConfig = def { activeBorderColor = "#7C7C7C"
                  , activeTextColor = "#C41C1C"
                  , activeColor = "#000000"
                  , inactiveBorderColor = "#7C7C7C"
                  , inactiveTextColor = "#EEEEEE"
                  , inactiveColor = "#000000"
                  , fontName = "xft:Envy Code R:style=Bold:size=8"
                  , decoWidth = 2
                  , decoHeight = 15
                  }

-- myLayout = avoidStruts $ minimize (mkToggle ( NOBORDERS ?? FULL ?? EOT ) $ tiled ||| oddtiled ||| Mirror tiled ||| tabbed shrinkText myTabConfig ||| noBorders Full ||| spiral (6/7))
-- Tabbed layout causes segfault with toggle - RANDOMLY, avoid until known to be fixed
getLayout = do
    host <- R.asks hostname
    return $ smartBorders $ avoidStruts $ minimize $ (mkToggle ( single NBFULL ) $ tiled
      ||| Mirror tiled
      ||| tabbed shrinkText myTabConfig
      ||| ThreeColMid 1 (3/100) (1/2)
      ||| ThreeCol 1 (3/100) (1/2)
      ||| Grid (screenRatio host)
      ||| noBorders streamwatching
      ||| noBorders Full
      ||| spiral (6/7))
      ||| (oddtiled host)
  where
   screenRatio "juno" = 16/9
   screenRatio "gordon" = 1366/768
   screenRatio "phaeloff" = screenRatio "gordon"
   screenRatio _ = 16/10

   oddRatio "phaelon" = 1 - 400 / 1440
   oddRatio "gordon" = 1 - 400 / 1366
   oddRatio "phaeloff" = oddRatio "gordon"
   oddRatio _ = 1 - 550 / 1920

   -- default tiling algorithm partitions the screen into two panes
   tiled       = Tall nmaster delta ratio

   -- Another tiling algorithm where the master pane is larger
   oddtiled h  = Tall nmaster delta $ oddRatio h

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
getManageHook = do
  myScratchpads <- getScratchpads
  return $ manageDocks
   <+> manageSpawn
   <+> (namedScratchpadManageHook $ myScratchpads)
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
   -- , roleName  =? "browser"            --> doShift "web"
   -- , className =? "firefox"            --> doShift "web"
   -- ,    (className =? "chromium")
   -- <||> (className =? "Chromium")
   -- -- debian variant of chromium
   -- <||> (className =? "chromium-browser")
   -- <||> (className =? "google-chrome")
   -- <||> (className =? "Google-chrome")
                                       -- --> doShift "web"
   , className =? "Thunderbird-bin"    --> doShift "3:msg"
   , className =? "Pidgin"             --> doShift "3:msg"
   , className =? "VirtualBox"         --> doShift "4:vm"
   , className =? "banshee-1"          --> doShift "5:media"
   , className =? "Ktorrent"           --> doShift "5:media"
   , className =? "Xchat"              --> doShift "5:media"
   , className =? "quasselclient"      --> doShift "quassel"
   , className =? "spotify"            --> doShift "music"
   , className =? "Steam"              --> doShift "games"
   , title =? "CS188 Pacman"           --> doShift "ai"
   , resource  =? "desktop_window"     --> doIgnore
   , resource  =? "kdesktop"           --> doIgnore
   , resource  =? "xfce4-notifyd"      --> doIgnore
   -- , className  =? "Vlc"                --> doShift "stream"
   -- , title =? "fd://0 - VLC media player" --> doShift "stream"
   ]

roleName :: Query String
roleName = stringProperty "WM_WINDOW_ROLE"

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
getAddExtendedWorkspaces = do
    myExtendedWorkspaces <- getExtendedWorkspaces
    return $ foldl1 (<+>) $ map addHiddenWorkspace $ myExtendedWorkspaces

getStartupHook = do
  myAddExtendedWorkspaces <- getAddExtendedWorkspaces
  spawnXmobar <- getSpawnXmobar
  return $ setWMName "LG3D"
     <+> myAddExtendedWorkspaces
     <+> docksStartupHook
     <+> dynStatusBarStartup spawnXmobar killXmobar

-- Minimize windows hook (to restore from taskbar)
getHandleEventHook = do
   spawnXmobar <- getSpawnXmobar
   -- numScreens <- R.asks numScreens
   let eventHook = fullscreenEventHook <+> docksEventHook <+> minimizeEventHook -- <+> debugKeyEvents
   -- if numScreens > 1 then
   return $ eventHook <+> dynStatusBarEventHook spawnXmobar killXmobar
   -- else
      -- return $ eventHook

myPP :: PP
myPP = xmobarPP {
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


myPP_inactive :: PP
myPP_inactive = myPP { ppCurrent = xmobarColor "#CEFFAC" "" }


-- DELME
getLogHook :: R.Reader MyConfig (X ())
getLogHook = return $ multiPP myPP myPP_inactive
  -- do
    -- spawnXmobar <- getSpawnXmobar
    -- numScreens <- R.asks numScreens
    -- if numScreens > 1 then
      -- return $ multiPP myPP myPP
    -- else
      -- return $ do
        -- h <- liftIO $ spawnXmobar 0
        -- liftIO $ logToTmpFile $ "Spawning single screen xmobar"
        -- let singleScreenPP = myPP { ppOutput = hPutStrLn h }
        -- dynamicLogWithPP singleScreenPP



-- myTrayer = "killall trayer; trayer --edge top --align left --margin 1770 --width 150 --widthtype pixel --height 16 --SetDockType true --expand false --padding 1 --tint 0x000000 --transparent true --alpha 0"
-- myTrayer = "killall trayer; trayer --edge top --align left --margin 1340 --width 100 --widthtype pixel --height 16 --padding 1 --tint 0x000000 --transparent true --alpha 0"
-- myTrayer "gordon" = "/bin/true"
-- myTrayer hostname = "killall trayer; trayer \
getSpawnTrayer :: R.Reader MyConfig (IO ())
getSpawnTrayer = do
    tWidth <- trayWidth
    tHeight <- trayHeight
    return $ do
      killTrayer
      numScreens <- countScreens
      mapM_ (spawnSingleTrayer tWidth tHeight) [0..numScreens-1]
  where
    spawnSingleTrayer width height sId = unsafeSpawn $ "sleep 1 && trayer \
       \--monitor " ++ (show sId) ++ " \
       \--edge top \
       \--align right \
       \--width " ++ width ++ " \
       \--widthtype pixel \
       \--height " ++ height ++ " \
       \--padding 1 \
       \--tint 0x000000 \
       \--transparent true \
       \--alpha 0 \
       \--expand false \
       \--SetDockType true 2>&1 | systemd-cat -t trayer"

    killTrayer :: IO ()
    killTrayer = unsafeSpawn "killall -9 trayer"


trayHeight = do
    host <- R.asks hostname
    return $ height host
  where
    height "mucku" = "19"
    height "mimir" = "17"
    height _ = "16"


trayWidth = do
    host <- R.asks hostname
    return $ width host
  where
    width "nurikum" = "150"
    width "jovis" = "50"
    width "gordon" = "75"
    width "phaeloff" = "74"
    width _ = "100"

trayMargin = do
    host <- R.asks hostname
    widthNurikum <- R.withReader (setHostname "nurikum") trayWidth
    widthGordon <- R.withReader (setHostname "gordon") trayWidth
    return $ margin widthNurikum widthGordon host
  where
    -- TODO: this is ugly, fix it!
    margin _ _ "nurikum" = "1700"
    margin widthNurikum _ "nurikum-standalone" = show (1920 + 1280 - (read widthNurikum))
    margin _ _ "phaelon" = "1340"
    margin _ _ "gordon" = "1291"
    margin _ widthGordon "phaeloff" = widthGordon
    margin _ _ "jovis" = "1230"
    margin _ _ _ = "1820"

getSpawnXmobar :: R.Reader MyConfig (ScreenId -> IO Handle)
getSpawnXmobar = return $ \(S sId) ->
    spawnPipe $ "~/.xmonad/bin/xmobar -x " ++ (show sId) ++ " ~/.xmonad/xmobar"

killXmobar :: IO ()
-- killXmobar = unsafeSpawn "killall xmobar"
killXmobar = return ()

-- myDefaultConfig "gordon" = xfceConfig
getDefaultConfig = return def

------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
--
main = do
   hostname <- getHostname
   numScreens <- countScreens
   -- logToTmpFile $ "Found " ++ show numScreens ++ " screens."
   let myConfig = MyConfig {
       hostname = hostname, numScreens = numScreens }
       spawnTrayer = R.runReader getSpawnTrayer myConfig
   spawnTrayer
   let myXmonadConfig = R.runReader getDefaults myConfig
   xmonad $ ewmh myXmonadConfig -- { logHook = multiPP myPP myPP }

-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.
--
getDefaults = do
   myAdditionalKeys <- getAdditionalKeys
   myDefaultConfig <- getDefaultConfig
   myKeys <- getKeys
   myLayout <- getLayout
   myLogHook <- getLogHook
   myManageHook <- getManageHook
   myStartupHook <- getStartupHook
   myTerminal <- getTerminal
   myWorkspaces <- getWorkspaces
   myHandleEventHook <- getHandleEventHook
   return $ myAdditionalKeys $ myDefaultConfig {
       -- simple stuff
       terminal            = myTerminal,
       focusFollowsMouse   = myFocusFollowsMouse,
       borderWidth         = myBorderWidth,
       modMask             = myModMask,
       --  numlockMask         = myNumlockMask,
       workspaces          = myWorkspaces,
       normalBorderColor   = myNormalBorderColor,
       focusedBorderColor  = myFocusedBorderColor,

       -- key bindings
       keys                = myKeys,
       mouseBindings       = myMouseBindings,

       -- hooks, layouts
       layoutHook          = smartBorders $ myLayout,
       manageHook          = myManageHook,
       startupHook         = myStartupHook,
       handleEventHook     = myHandleEventHook,

       -- misc
       logHook             = myLogHook
   }

debugStuff :: X ()
debugStuff = withWindowSet (\ws -> do
    -- liftIO $ print ws
    liftIO $ logToTmpFile $ show (W.screens ws)
    liftIO $ logToTmpFile $ show ws
    liftIO $ logToTmpFile $ show (W.currentTag ws)
  )

myAppendFile :: FilePath -> String -> IO ()
myAppendFile f s = do
  withFile f AppendMode $ \h -> do
    hPutStrLn h s

logToTmpFile :: String -> IO ()
logToTmpFile = myAppendFile "/tmp/xmonad.log" . (++ "\n")

-- vim: ft=haskell
