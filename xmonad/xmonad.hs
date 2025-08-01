-- Originally taken from: http://github.com/vicfryzel/xmonad-config

import GetHostname

import qualified Control.Monad.Trans.Reader as R
import Control.Monad (when)

import Data.List (sortOn)

import System.IO
import System.Environment
import System.Exit
import XMonad
import XMonad.Hooks.DebugKeyEvents
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.Minimize
import XMonad.Hooks.Modal
import XMonad.Hooks.SetWMName
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
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
import XMonad.Layout.BinaryColumn
import XMonad.Layout.FixedColumn
import XMonad.Layout.GridVariants
import XMonad.Layout.IndependentScreens (countScreens, withScreens)
import XMonad.Layout.LayoutScreens
import XMonad.Layout.Minimize
import XMonad.Layout.MultiColumns
import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.NoBorders
import XMonad.Layout.Reflect (reflectVert)
import XMonad.Layout.ResizableTile
import XMonad.Layout.SimpleDecoration
import XMonad.Layout.Spiral
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.TwoPane
import XMonad.Util.Run (spawnPipe, safeSpawn, unsafeSpawn)
import XMonad.Util.SpawnOnce (spawnOnce)
import XMonad.Util.EZConfig (additionalKeysP)
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
    -- go _ = "urxvtc"
    go _ = "alacritty"

getAltTerminal :: R.Reader MyConfig String
getAltTerminal = do
    host <- R.asks hostname
    return $ go host
  where
    -- go _ = "urxvtc"
    go _ = "urxvt"

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
    ,  NS "btop" (termTitle ++ "btop -e btop") (title =? "btop") defaultOverlay
    ,  NS "htop" (termTitle ++ "htop -e htop") (title =? "htop") defaultOverlay
    ,  NS "shell" (termTitle ++ "shell") (title =? "shell") defaultOverlay
    ,  NS "ipython" (termTitle ++ "ipython -e ipython") (title =? "ipython") defaultOverlay
    ,  NS "ptpython" (termTitle ++ "\"Python REPL (ptpython)\" -e ptpython") (title =? "Python REPL (ptpython)") defaultOverlay
    ,  NS "nvim-ghost" (termTitle ++ "nvim-ghost -e nvim  +GhostStart") (title =? "nvim-ghost") defaultOverlay
    ,  NS "nvim-scratchpad" (termTitle ++ "nvim-scratchpad -e nvim /tmp/scratchpad" ) (title =? "nvim-scratchpad") defaultOverlay
    ,  NS "neovide-ghost" "neovide -- +GhostStart '+set titlestring=neovide-ghost' '+set title'" (title =? "neovide-ghost") defaultOverlay
       -- run stardict, find it by class name, place it in the floating window
       -- 1/6 of screen width from the left, 1/6 of screen height
       -- from the top, 2/3 of screen width by 2/3 of screen height
       --  NS "stardict" "stardict" (className =? "Stardict")
       --  (customFloating $ W.RationalRect (1/6) (1/6) (2/3) (2/3)) ,
    -- run gvim, find by role, don't float with nonFloating
    ,  NS "notes-vimwiki" (spawnNotes termTitle) findNotes defaultOverlay
    ,  NS "notes-neorg" (spawnNotesNeorg termTitle) findNotes defaultOverlay
    ,  NS "notes-vimwiki-neovide" spawnNotes_neovide findNotesNeovide defaultOverlay
    ,  NS "notes-neorg-neovide" spawnNotesNeorg_neovide findNotesNeovide defaultOverlay
    ,  NS "todos" (termTitle ++ "nvim-todos -e zsh -c 'source $HOME/.zshrc; todos'") (title =? "nvim-todos") defaultOverlay
    ,  NS "nv-todos" "neovide-todos" findTodos defaultOverlay
    ,  NS "bluetuith" (termTitle ++ "bluetuith -e bluetuith" ) (title =? "bluetuith") defaultOverlay
    ,  NS "volumecontrol" "pavucontrol -t 3" (title =? "Volume Control") defaultOverlay
    ,  NS "easyeffects" "easyeffects" (title =? "Easy Effects") defaultOverlay
    ,  NS "presentation-terminal" (termTitle ++ "presentation-terminal") (title =? "presentation-terminal") presenterLayout
    -- ,  NS "rev-backlog-markdown" (termTitle ++ "rev-backlog-markdown -e rev-backlog -c -m") (title =? "rev-backlog-markdown") defaultOverlay
    -- ,  NS "rev-backlog-browser" (termTitle ++ "rev-backlog-browser -e rev-backlog -w") (title =? "rev-backlog-browser") defaultOverlay
    ,  NS "rev-backlog-markdown" (termTitle ++ "rev-backlog-markdown -e tmux -c 'revcli backlog query -c -m'") (title =? "rev-backlog-markdown") defaultOverlay
    ,  NS "rev-backlog-browser" (termTitle ++ "rev-backlog-browser -e revcli backlog query -b") (title =? "rev-backlog-browser") defaultOverlay
    ]
  where
       -- unfortunately neovide is not yet running as expected (does not allow floating and resizing) -> keep nvim in terminal for now
       -- role = stringProperty "WM_WINDOW_ROLE"
       spawnNotes termTitle = "cd ~/wiki && " ++ termTitle ++ "notes -e nvim +VimwikiMakeDiaryNote"
       spawnNotesNeorg termTitle = "cd ~/wiki/neorg && " ++ termTitle ++ "notes -e nvim '+Neorg journal today'"
       -- spawnNotes_neovide = "neovide --multigrid --maximized --x11-wm-class neovide-notes -- '+cd ~/wiki' '+VimwikiMakeDiaryNote' '+set columns=" ++ (show numCols) ++ "'"
       -- spawnNotesNeorg_neovide = "neovide --multigrid --maximized --x11-wm-class neovide-notes -- '+cd ~/.vimwiki/neorg/journal' '+Neorg journal today' '+set columns=" ++ (show numCols) ++ "'"
       spawnNotes_neovide = "neovide --maximized --x11-wm-class neovide-notes -- '+cd ~/wiki' '+VimwikiMakeDiaryNote'"
       spawnNotesNeorg_neovide = "neovide --maximized --x11-wm-class neovide-notes -- '+cd ~/wiki/neorg' '+Neorg journal today'"
       -- findNotes = role =? "notes"
       findNotesNeovide = className =? "neovide-notes"
       findTodos = className =? "neovide-todos"
       findNotes = title =? "notes"
       defaultOverlay = customFloating $ W.RationalRect l t w h
       l = 0.35
       t = 0.05
       w = 1.0 - l
       h = 0.85
       numCols = 206
       -- TODO: get width from env
       -- numCols = flip (-) 2 $ floor $ 1920.0 * w / 7.0
       presenterLayout = customFloating $ W.RationalRect 0.0 (160/1600) 1 (1080/1600)

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
    three = [ "a", "b", "c"]
    two = [ "a", "b" ]

getExtendedWorkspaces :: R.Reader MyConfig [String]
getExtendedWorkspaces = do
    host <- R.asks hostname
    -- ns <- R.asks numScreens
    -- return $ withScreens (S ns) $ extws host
    return $ [ "NSP" ] ++ extws host ++ [ "z" ]
  where
    extws "mimir" = [ "1pw"
                    , "chat"
                    , "code"
                    , "fdc"
                    , "gchat"
                    , "k9s"
                    , "meeting"
                    , "music"
                    , "nix"
                    , "recruiting"
                    , "root"
                    , "rust"
                    , "web"
                    , "z" ]

    extws "mucku" = [ "chat"
                    , "ef"
                    , "games"
                    , "kdb"
                    , "music"
                    , "root"
                    , "tv"
                    , "voice"
                    , "web"
                    , "z" ]

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
     prg _ = "rofi -show run -sort"
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
    return . spawn $ go host
  where
    go "phaelon" = "/bin/sh ~/git/dotfiles_desktop/scripts/go_standby.sh"
    go _ = "slock"
-- lockSpawner _ = spawn "xscreensaver-command -lock"

-- displayOrder "nurikum" = [xK_w, xK_q, xK_e]
getDisplayOrder = do
    host <- R.asks hostname
    num <- R.asks numScreens
    return $ hlp host num
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
    , ((modMask .|. controlMask,    xK_m),       spawnHere "html_to_markdown_link")

    -- refresh montiros
    , ((modMask,                    xK_x),       spawnHere "nemo")

    -- launch gmrun
    -- , ((modMask .|. shiftMask,       xK_p        ), spawnHere "eval \"exec ~/bin/mydmenu\"")

    -- launch emoji picker
    , ((modMask .|. controlMask,    xK_i        ), spawnHere "rofimoji --action copy --files all --skin-tone neutral")

    -- launch pavucontrol / volume control
    , ((modMask ,                   xK_c        ), namedScratchpadAction myScratchpads "volumecontrol")
    , ((modMask .|. mod1Mask,       xK_c        ), namedScratchpadAction myScratchpads "easyeffects")

    -- bleach (clear) notifications
    , ((modMask ,                   xK_b        ), spawn "dunstctl close")
    -- launch browser
    -- , ((modMask ,                   xK_b        ), spawn "open-default-browser")
    -- launch browser with proxy enabled
    , ((modMask .|. shiftMask,      xK_b        ), spawn myBrowserProxy)

    -- clipboard management
    -- copy selection -> clipboard
    , ((modMask .|. controlMask,    xK_k        ), spawn "sh -c 'xclip -o | xclip -i -selection clipboard'")

    -- take screenshot
    , ((modMask .|. controlMask,    xK_p        ), spawnHere "flameshot gui")
    -- , ((modMask .|. controlMask,    xK_p        ), spawnHere "import `date +screens/screen_%F_%H-%M.png`")
    -- , ((modMask .|. controlMask,                  xK_p        ), spawnHere "maim -u -m 10 -s |  xclip -selection clipboard -t image/png")
    -- , ((modMask .|. controlMask .|. shiftMask,    xK_p        ), spawnHere "maim -u -s $(date +screens/screen_%F_%H-%M.png)")
    -- , ((modMask .|. controlMask .|. shiftMask .|. mod1Mask,    xK_p        ), spawnHere "maim -u $(date +screens/screen_%F_%H-%M.png)")

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

    -- Shrink the mirror area
    , ((modMask .|. controlMask,    xK_comma    ), sendMessage MirrorShrink)
    -- Expand the mirror area
    , ((modMask .|. controlMask,    xK_period   ), sendMessage MirrorExpand)

    -- Push window back into tiling
    , ((modMask,                    xK_y        ), withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area
    , ((modMask .|. shiftMask,      xK_comma   ), sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ((modMask .|. shiftMask,      xK_period    ), sendMessage (IncMasterN (-1)))

    -- Toggle fullscreen
    , ((modMask,                    xK_p        ), sendMessage $ Toggle NBFULL )

    -- toggle the status bar gap TODO, update this binding with avoidStruts,
    , ((modMask,                    xK_n        ), sendMessage ToggleStruts )

    -- , ((modMask,                    xK_F7       ), sendMessage $ DeArrange)
    -- set window into presenter mode (to be used with obs)
    -- , ((modMask .|. controlMask,    xK_F7       ), sendMessage $ SetGeometry $ Rectangle 1920 160 1920 1080)

    -- Minimize windows
    , ((modMask,                    xK_u        ), withFocused minimizeWindow )
    , ((modMask .|. shiftMask,      xK_u        ), withLastMinimized maximizeWindow)

    -- Quit xmonad
    , ((modMask .|. shiftMask,      xK_F4       ), myExitXmonad)

    -- Restart xmonad
    , ((modMask,                    xK_F5       ), restart "xmonad" True)
    ] ++

    -- Prompts
    ------------------------------
    -- Switch to window
    [
    -- ((modMask,                      xK_o        ), windowPrompt myXPConfig Goto allWindows )
    -- SSH prompt
    --, (( modMask,                 xK_s        ), sshPrompt myXPConfig)
    -- Does not really work as expected, put on hold
    ] ++

    -- Scratch Pads
    ------------------------------
    -- [ ((modMask .|. controlMask,      xK_slash        ), namedScratchpadAction myScratchpads "notes" )
    [ ((modMask .|. controlMask,      xK_slash        ), namedScratchpadAction myScratchpads "todos" )
    , ((modMask,                      xK_slash        ), namedScratchpadAction myScratchpads "notes-neorg" )
    -- , ((modMask,                      xK_slash        ), namedScratchpadAction myScratchpads "notes-neorg-neovide" )
    , ((modMask .|. shiftMask,        xK_slash        ), namedScratchpadAction myScratchpads "htop" )
    , ((modMask,                      xK_apostrophe   ), namedScratchpadAction myScratchpads "shell" )
    , ((modMask .|. shiftMask,        xK_apostrophe   ), namedScratchpadAction myScratchpads "alsamixer" )
    , ((modMask,                      xK_backslash    ), namedScratchpadAction myScratchpads "btop" )
    , ((modMask .|. shiftMask,        xK_backslash    ), namedScratchpadAction myScratchpads "bashtop" )
    , ((modMask,                      xK_g            ), namedScratchpadAction myScratchpads "nvim-scratchpad" )
    -- , ((modMask .|. controlMask,      xK_z            ), spawnHere "copy-to-scratchpad" )
    , ((modMask .|. shiftMask,        xK_p            ), namedScratchpadAction myScratchpads myPythonPrompt )
    , ((modMask .|. controlMask,      xK_F7           ), namedScratchpadAction myScratchpads "presentation-terminal" )
    -- , ((modMask .|. controlMask,      xK_m            ), namedScratchpadAction myScratchpads "rev-backlog-markdown")
    , ((modMask .|. controlMask,      xK_b            ), namedScratchpadAction myScratchpads "rev-backlog-browser")
    , ((modMask .|. controlMask,      xK_t            ), namedScratchpadAction myScratchpads "bluetuith")
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

    -- modes
    -- mnemonic: swiTch layouT
    [ ((modMask,                    xK_t        ), setMode "switchLayout" )
    , ((modMask,                    xK_o        ), setMode "run"          )
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
    [ ((modMask, xK_s),  swapPrevScreen )
    , ((modMask, xK_d),  swapNextScreen )
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
    [   ((modMask .|. controlMask .|. shiftMask, xK_F8), debugStuff)
    ]
    ++
    [
      -- launch password helper
      ((modMask, xK_F8),    spawn "rofi -modi 1pass:rofi-1pass -show 1pass")
    ]
    ++
    -- Toggle Microphone in Zoom
    -- [   ((modMask, xK_F9),  spawn "meet-toggle-audio" >> spawn "zoom-toggle-audio")
    -- Toggle bluetooth mode
    [   ((modMask, xK_F9),  spawn "toggle-bluetooth-audio")
    ]
    ++
    -- Music controller
    [
        ((modMask, xK_F10), spawn "myplayerctl prev")
      , ((modMask, xK_F11), spawn "myplayerctl next")
      , ((modMask, xK_F12), spawn "myplayerctl play-pause")
    ]
    ++
    [   ((modMask .|. controlMask, xK_F8), spawn "open-dd-log-from-clipboard")
    ]
    ++
    -- Reset monitor configuration to use all available monitors
    [
        ((modMask .|. controlMask, xK_F10), spawn "autorandr -c")
      , ((modMask .|. controlMask, xK_F12), spawn "rofi-autorandr")
    ]

withExitMode :: [(KeySym, X () )] -> [(KeySym, X () )]
withExitMode = map $ \(key, action) -> (key, action >> exitMode)

withoutModMask :: [(KeySym, X () )] -> [((KeyMask, KeySym), X () )]
withoutModMask = map $ \(key, action) -> ((noModMask, key), action)

modeRun = mode "run" $ \cfg ->
    M.fromList
    -- [((noModMask,     xK_d        ), setMode "datadog" )]
    [((noModMask,     xK_d        ), spawn "open-dd-log-from-clipboard" >> exitMode )]

-- modeDatadog = mode "datadog" $ \cfg ->
    -- M.fromList . withExitMode $
    -- [((noModMask,     xK_l        ), spawn "open-dd-log-from-clipboard" )]

-- layout switcher
modeSwitchLayout = mode "switchLayout" $ \(conf@(XConfig {XMonad.modMask = modMask})) ->
    M.fromList . withoutModMask $
    [ (xK_q, rescreen )]
    ++
    withExitMode
    -- ultra-wide settings
    [ (xK_w, layoutSplitScreen 2 (TwoPane 0.5 0.5) )
    , (xK_s, layoutSplitScreen 2 (TwoPane 0 (2/3)))
    , (xK_e, layoutSplitScreen 3 (ThreeColMid 1 (3/100) (1/2)))
    , (xK_d, layoutSplitScreen 3 (ThreeCol 1 (3/100) (1/3)))
    -- upper left corner
    , (xK_a, layoutSplitScreen 2 (Mirror $ TwoPane 0 ((1600-1080)/1600)))
    , (xK_z, layoutSplitScreen 3 (Mirror $ TwoPane 0 (1/3)))
    -- lower right corner
    , (xK_c, layoutSplitScreen 3 (ResizableTall 1 (3/100) (1/2) [1080/800, (1600-1080)/800]))
    , (xK_r, layoutSplitScreen 3 (Tall 1 (3/100) (1/2 + 13/100)))
    , (xK_f, layoutSplitScreen 3 (Tall 1 (3/100) (2/3)))

    -- , ((modMask .|. controlMask .|. shiftMask,    xK_s        ), layoutSplitScreen 2 (Tall 1 (3/100) (1/2)))
    ]

allModes = [ modeRun
           -- , modeDatadog
           , modeSwitchLayout
           ]

-- apply action current workspace in screen
applyToWSinScreen :: Int -> (WorkspaceId -> WindowSet -> WindowSet) -> X ()
applyToWSinScreen screen action = do
    wsScreens <- withWindowSet $ return . sortOn W.screen  . W.screens
    numPhysicalScreens <- countScreens
    -- liftIO $ logToTmpFile $ "Num physical screens: " ++ show numPhysicalScreens ++
      -- " Num virtual screens: " ++ show (length wsScreens)
    -- liftIO $ mapM_ (\(i, s) -> logToTmpFile ("Screen #" ++ show i ++ ": " ++ show s)) $ zip [0..] wsScreens
    let numScr = length wsScreens
    -- TODO: Add check for one physical screen
        screenIdx = case () of
            _ | False && numScr == 3 && numPhysicalScreens == 1 -> case screen of
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
     [ ("<XF86AudioPlay>", spawn "myplayerctl play-pause")
     , ("<XF86AudioNext>", spawn "myplayerctl next")
     , ("<XF86AudioPrev>", spawn "myplayerctl previous")
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
      ||| terminal
      ||| Mirror tiled
      ||| tabbed shrinkText myTabConfig
      ||| BinaryColumn 1.0 30
      ||| multiCol [1] 1 (3/100) (-0.5)
      ||| ThreeColMid 1 (3/100) (1/2)
      ||| ThreeCol 1 (3/100) (1/3)
      ||| ThreeCol 1 (3/100) (1/2)
      ||| Grid (screenRatio host)
      ||| noBorders streamwatching)
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
   tiled       = ResizableTall nmaster delta ratio []
   terminal    = reflectVert $ Mirror $ ResizableTall nmaster delta (15/100) []

   -- Another tiling algorithm where the master pane is larger
   oddtiled h  = ResizableTall nmaster delta (oddRatio h) []

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
  return $ manageSpawn
   <+> (namedScratchpadManageHook $ myScratchpads)
   <+> composeAll
   [ className =? "MPlayer"            --> doFloat
   , className =? "Smplayer"           --> doFloat
   , className =? "Psx.real"           --> doFloat
   , className =? "Gimp"               --> doFloat
   , className =? "Galculator"         --> doFloat
   , resource  =? "Komodo_find2"       --> doFloat
   , resource  =? "compose"            --> doFloat
   , className =? "ripdrag"            --> doFloat
   , className =? "blobdrop"           --> doFloat
   -- , roleName  =? "browser"            --> doShift "web"
   -- , className =? "firefox"            --> doShift "web"
   -- ,    (className =? "chromium")
   -- <||> (className =? "Chromium")
   -- -- debian variant of chromium
   -- <||> (className =? "chromium-browser")
   -- <||> (className =? "google-chrome")
   -- <||> (className =? "Google-chrome")
                                       -- --> doShift "web"
   , className =? "Thunderbird-bin"           --> doShift "3:msg"
   , className =? "Pidgin"                    --> doShift "3:msg"
   , className =? "VirtualBox"                --> doShift "4:vm"
   , className =? "banshee-1"                 --> doShift "5:media"
   , className =? "Ktorrent"                  --> doShift "5:media"
   , className =? "Xchat"                     --> doShift "5:media"
   , className =? "quasselclient"             --> doShift "quassel"
   , className =? "spotify"                   --> doShift "music"
   , className =? "Steam"                     --> doShift "games"
   , title =? "CS188 Pacman"                  --> doShift "ai"
   , resource  =? "desktop_window"            --> doIgnore
   , resource  =? "kdesktop"                  --> doIgnore
   , resource  =? "xfce4-notifyd"             --> doIgnore
   , className =? "microsoft teams - preview" <||> className =? "Microsoft Teams - Preview" --> doShift "teams"
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
  return $ setWMName "LG3D"
     <+> myAddExtendedWorkspaces

-- Minimize windows hook (to restore from taskbar)
getHandleEventHook = do
   -- numScreens <- R.asks numScreens
   let eventHook = minimizeEventHook -- <+> debugKeyEvents
   -- if numScreens > 1 then
   return $ eventHook
   -- else
      -- return $ eventHook

myPP :: R.Reader MyConfig PP
myPP = do
  tWidth <- trayWidth
  return $ xmobarPP {
      ppTitle = xmobarColor "#FFB6B0" "" . shorten tWidth
      --  , ppCurrent = xmobarColor "#CEFFAC" ""
      , ppCurrent = xmobarColor "#0CC6DA" ""
      , ppVisible = xmobarColor "#CEFFAC" ""
      , ppHidden = ppHidden xmobarPP . noScratchPad
      , ppHiddenNoWindows = xmobarColor "#777777" "" . noScratchPad
      , ppSep = "   "
      --  , ppSort = DO.getSortByOrder
  }
  where
      noScratchPad ws = if ws == "NSP" then "" else ws

-- myTrayer = "killall trayer; trayer --edge top --align left --margin 1770 --width 150 --widthtype pixel --height 16 --SetDockType true --expand false --padding 1 --tint 0x000000 --transparent true --alpha 0"
-- myTrayer = "killall trayer; trayer --edge top --align left --margin 1340 --width 100 --widthtype pixel --height 16 --padding 1 --tint 0x000000 --transparent true --alpha 0"
-- myTrayer "gordon" = "/bin/true"
-- myTrayer hostname = "killall trayer; trayer \
getSpawnTrayer :: R.Reader MyConfig (IO ())
getSpawnTrayer = return $ do
    unsafeSpawn "killall -9 trayer"
    unsafeSpawn "sleep 1 && ~/.xmonad/run-trayer.sh"

numIcons = do
  return 6

trayWidth = do
  nI <- numIcons
  height <- trayHeight
  return $ nI * height


trayHeight = do
    host <- R.asks hostname
    return $ height host
  where
    -- height "mucku" = "19"
    -- height "mimir" = "17"
    height _ = 18


getSpawnXmobar :: R.Reader MyConfig (ScreenId -> X StatusBarConfig)
-- spawnPipe $ "~/.xmonad/bin/xmobar -x " ++ (show sId) ++ " ~/.xmonad/xmobar"
getSpawnXmobar = do
    pp <- myPP
    return $ \sId -> (liftIO $ go pp sId)
 where
    go :: PP -> ScreenId -> IO StatusBarConfig
    go pp (S 0) = do
      home <- getEnv "HOME"
      let logProp = "_XMONAD_LOG"
          -- rcFile = home ++ "/.config/xmobar/.xmobarrc"
          -- command = home ++ "/.xmonad/bin/xmobar -x " ++ (show sId) ++ " " ++ rcFile
          -- command = "xmobar -x 0 " ++ rcFile
          command = "xmobar -x 0"
      return $ statusBarPropTo logProp command (pure pp)
    go _ (S _) = mempty

-- myDefaultConfig "gordon" = xfceConfig
getDefaultConfig = return def

------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
--
main = do
   hostname <- getHostname
   numScr <- countScreens
   -- logToTmpFile $ "Found " ++ show numScr ++ " screens."
   let myConfig = MyConfig {
       hostname = hostname, numScreens = numScr }
       spawnTrayer = R.runReader getSpawnTrayer myConfig
       spawnXmobar = R.runReader getSpawnXmobar myConfig
   spawnTrayer
   let myXmonadConfig = ewmhFullscreen . dynamicEasySBs spawnXmobar $ R.runReader getDefaults myConfig
   xmonad . modal allModes $ ewmh myXmonadConfig

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
       workspaces          = withScreens 1 myWorkspaces,
       normalBorderColor   = myNormalBorderColor,
       focusedBorderColor  = myFocusedBorderColor,

       -- key bindings
       keys                = myKeys,
       mouseBindings       = myMouseBindings,

       -- hooks, layouts
       layoutHook          = smartBorders $ myLayout,
       manageHook          = myManageHook,
       startupHook         = myStartupHook,
       handleEventHook     = myHandleEventHook
   }

debugStuff :: X ()
debugStuff = withWindowSet (\ws -> do
    -- liftIO $ print ws
    -- liftIO $ logToTmpFile $ show (W.screens ws)
    liftIO $ logToTmpFile $ show ws
    -- liftIO $ logToTmpFile $ show (W.currentTag ws)
  )

myAppendFile :: FilePath -> String -> IO ()
myAppendFile f s = do
  withFile f AppendMode $ \h -> do
    hPutStrLn h s

logToTmpFile :: String -> IO ()
logToTmpFile = myAppendFile "/tmp/xmonad.log" . (++ "\n")

-- vim: ft=haskell
