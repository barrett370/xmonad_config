  -- Base
import XMonad
    ( mod1Mask,
      mod4Mask,
      gets,
      io,
      spawn,
      (|||),
      xmonad,
      (-->),
      (<&&>),
      (<+>),
      (<||>),
      (=?),
      className,
      composeAll,
      doFloat,
      doShift,
      resource,
      stringProperty,
      title,
      sendMessage,
      windows,
      withFocused,
      KeyMask,
      Window,
      Dimension,
      Default(def),
      Query,
      WindowSet,
      X,
      XConfig(manageHook, handleEventHook, modMask, terminal,
              startupHook, layoutHook, workspaces, borderWidth,
              normalBorderColor, focusedBorderColor, logHook),
      XState(windowset),
      ChangeLayout(NextLayout),
      Full(Full),
      IncMasterN(IncMasterN),
      Mirror(Mirror),
      Resize(Expand, Shrink) )
import System.IO (hPutStrLn)
import System.Exit (exitSuccess)
import qualified XMonad.StackSet as W

    -- Actions
import XMonad.Actions.CopyWindow (kill1, killAllOtherCopies)
import XMonad.Actions.CycleWS (moveTo, shiftTo, WSType(..), nextScreen, prevScreen, nextWS, prevWS)
import XMonad.Actions.GridSelect ( colorRangeFromClassName )
import XMonad.Actions.MouseResize ( mouseResize )
import XMonad.Actions.Promote ( promote )
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import XMonad.Actions.WithAll (sinkAll, killAll)

    -- Data
import Data.Monoid ( Endo)
import Data.Tree ()
import Data.List 

    -- Hooks
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, xmobarPP, xmobarColor, shorten, PP(..))
import XMonad.Hooks.DynamicProperty
import XMonad.Hooks.DynamicBars ()
import XMonad.Hooks.EwmhDesktops ( ewmh, fullscreenEventHook )  -- for some fullscreen events, also for xcomposite in obs.
import XMonad.Hooks.FadeInactive ( fadeInactiveLogHook )
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat)
import XMonad.Hooks.ServerMode
    ( serverModeEventHook,
      serverModeEventHookCmd,
      serverModeEventHookF )
import XMonad.Hooks.SetWMName ()
import XMonad.Hooks.WorkspaceHistory ( workspaceHistoryHook )

    -- Layouts
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.SimplestFloat (SimplestFloat,  simplestFloat )
import XMonad.Layout.Spiral
import XMonad.Layout.ResizableTile
    ( MirrorResize(MirrorExpand, MirrorShrink),
      ResizableTall(ResizableTall) )
import XMonad.Layout.Tabbed
    (TabbedDecoration,
      shrinkText,
      tabbed,
      Theme(fontName, activeColor, inactiveColor, activeBorderColor,
            inactiveBorderColor, activeTextColor, inactiveTextColor) )
import XMonad.Layout.ThreeColumns ( ThreeCol(ThreeCol) )

    -- Layouts modifiers
import XMonad.Layout.LayoutModifier ( ModifiedLayout )
import XMonad.Layout.LimitWindows (LimitWindows, limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.Magnifier (Magnifier,  magnifier )
import XMonad.Layout.MultiToggle (HCons, MultiToggle, mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders ( noBorders, smartBorders )
import XMonad.Layout.Renamed (renamed, Rename(Replace))
import XMonad.Layout.Spacing
    ( spacingRaw, Border(Border), Spacing )
import XMonad.Layout.WindowArranger (WindowArranger, windowArrange, WindowArrangerMsg(..))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

    -- Prompt
import XMonad.Prompt ( Direction1D(Prev, Next) )
import XMonad.Prompt.Input ()
import XMonad.Prompt.FuzzyMatch ()
import XMonad.Prompt.Man ()
import XMonad.Prompt.Pass ()
import XMonad.Prompt.Ssh ()
import XMonad.Prompt.XMonad ()

    -- Utilities
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.NamedScratchpad
    ( customFloating,
      namedScratchpadAction,
      namedScratchpadManageHook,
      NamedScratchpad(NS) )
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.SpawnOnce ( spawnOnce )
import XMonad.Layout.Decoration (DefaultShrinker, Decoration)
import XMonad.Layout.Simplest (Simplest)

myFont :: String
myFont = "xft:Fira Code Nerd Font:bold:size=9:antialias=true:hinting=true"

myModMask :: KeyMask
myModMask = mod4Mask       -- Sets modkey to super/windows key

myTerminal :: String
myTerminal = "kitty"   -- Sets default terminal

myBrowser :: String
myBrowser = "firefox"               -- Sets qutebrowser as browser for tree select

myEditor :: String
myEditor = myTerminal ++ " -e nvim "    -- Sets vim as editor for tree select

myBorderWidth :: Dimension
myBorderWidth =  2        -- Sets border width for windows

myNormColor :: String
myNormColor   = "#292d3e"  -- Border color of normal windows

myFocusColor :: String
myFocusColor  = "#00FFFF"  -- Border color of focused windows
--myFocusColor  = myNormColor -- Border color of focused windows

altMask :: KeyMask
altMask = mod1Mask         -- Setting this for use in xprompts

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

myStartupHook :: X ()
myStartupHook = do
          --spawnOnce "picom --config /home/sam/.config/picom/picom.conf &"
          spawnOnce "picom -b &"
          spawnOnce "setxkbmap -option caps:escape"
          spawnOnce "xrandr --output DP-2 --mode 2560x1440 --primary --output DP-0 --mode 1920x1200 --left-of DP-2"
          spawnOnce "/usr/bin/dunst &"
          -- spawnOnce "xsetroot -cursor_name left_ptr &"
          -- spawnOnce "nitrogen --restore &"
          spawnOnce "feh --bg-scale $HOME/.wallpapers/0032.jpg"

myColorizer :: Window -> Bool -> X (String, String)
myColorizer = colorRangeFromClassName
                  (0x29,0x2d,0x3e) -- lowest inactive bg
                  (0x29,0x2d,0x3e) -- highest inactive bg
                  (0xc7,0x92,0xea) -- active bg
                  (0xc0,0xa7,0x9a) -- inactive fg
                  (0x29,0x2d,0x3e) -- active fg

myScratchPads :: [NamedScratchpad]
myScratchPads = [ NS "terminal" spawnTerm findTerm manageTerm
                , NS "spotify" spawnSpotify findSpotify manageSpotify
                , NS "htop"    spawnHtop findHtop manageHtop
                -- , NS "zotero"    spawnZotero findZotero manageZotero
                ]
  where
    spawnTerm  = myTerminal ++ " --class Scratchpad"
    findTerm   = className =? "Scratchpad"
    manageTerm = customFloating $ W.RationalRect l t w h
               where
                 h = 0.9
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w
    -- spawnSpotify  = "st -c SpotifyTui -T foo -e spt"
    spawnSpotify = "spotify"
    --findSpotify = className =? "SpotifyTui"
    findSpotify = className =? "Spotify"
    manageSpotify = customFloating $ W.RationalRect l t w h
               where
                 h = 0.9
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w
    spawnHtop = myTerminal ++ " --class Htop -e htop"
    findHtop = className =? "Htop"
    manageHtop = customFloating $ W.RationalRect l t w h
               where
                 h = 0.5
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w
    spawnZotero  = "zotero"
    findZotero = className =? "Zotero"
    manageZotero = customFloating $ W.RationalRect l t w h
               where
                 h = 0.9
                 w = 0.9
                 t = 0.95 -h
                 l = 0.95 -w

mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

-- Below is a variation of the above except no myNormColor borders are applied
-- if fewer than two windows. So a single window has no gaps.
mySpacing' :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing' i = spacingRaw True (Border i i i i) True (Border i i i i) True

-- Defining a bunch of layouts, many that I don't use.
tall :: ModifiedLayout Rename (ModifiedLayout LimitWindows (ModifiedLayout Spacing ResizableTall)) a
tall     = renamed [Replace "tall"]
           $ limitWindows 12
           $ mySpacing 8
           $ ResizableTall 1 (3/100) (1/2) []
magnify :: ModifiedLayout Rename (ModifiedLayout Magnifier (ModifiedLayout LimitWindows (ModifiedLayout Spacing ResizableTall))) a
magnify  = renamed [Replace "magnify"]
           $ magnifier
           $ limitWindows 12
           $ mySpacing 8
           $ ResizableTall 1 (3/100) (1/2) []
monocle :: ModifiedLayout Rename (ModifiedLayout LimitWindows Full) a
monocle  = renamed [Replace "monocle"]
           $ limitWindows 20 Full
floats :: ModifiedLayout Rename (ModifiedLayout LimitWindows (ModifiedLayout WindowArranger SimplestFloat)) Window
floats   = renamed [Replace "floats"]
           $ limitWindows 20 simplestFloat
grid :: ModifiedLayout Rename (ModifiedLayout LimitWindows (ModifiedLayout Spacing (MultiToggle (HCons StdTransformers EOT) Grid))) a
grid     = renamed [Replace "grid"]
           $ limitWindows 12
           $ mySpacing 8
           $ mkToggle (single MIRROR)
           $ Grid (16/10)
spirals :: ModifiedLayout Rename (ModifiedLayout Spacing SpiralWithDir) a
spirals  = renamed [Replace "spirals"]
           $ mySpacing' 8
           $ spiral (6/7)
threeCol :: ModifiedLayout Rename (ModifiedLayout LimitWindows (ModifiedLayout Spacing ThreeCol)) a
threeCol = renamed [Replace "threeCol"]
           $ limitWindows 7
           $ mySpacing' 4
           $ ThreeCol 1 (3/100) (1/2)
threeRow :: ModifiedLayout Rename (ModifiedLayout LimitWindows (ModifiedLayout Spacing (Mirror ThreeCol))) a
threeRow = renamed [Replace "threeRow"]
           $ limitWindows 7
           $ mySpacing' 4
           -- Mirror takes a layout and rotates it by 90 degrees.
           -- So we are applying Mirror to the ThreeCol layout.
           $ Mirror
           $ ThreeCol 1 (3/100) (1/2)
tabs :: ModifiedLayout Rename (ModifiedLayout (Decoration TabbedDecoration DefaultShrinker) Simplest) Window
tabs     = renamed [Replace "tabs"]
           -- I cannot add spacing to this layout because it will
           -- add spacing between window and tabs which looks bad.
           $ tabbed shrinkText myTabConfig
  where
    myTabConfig = def { fontName            = "xft:Fira Code Nerd Font:regular:pixelsize=11"
                      , activeColor         = "#292d3e"
                      , inactiveColor       = "#3e445e"
                      , activeBorderColor   = "#292d3e"
                      , inactiveBorderColor = "#292d3e"
                      , activeTextColor     = "#ffffff"
                      , inactiveTextColor   = "#d0d0d0"
                      }
-- The layout hook
myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts floats $ smartBorders $
               mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
               -- I've commented out the layouts I don't use.
               myDefaultLayout =     tall
                                 ||| noBorders magnify
                                 ||| noBorders monocle
                                 ||| floats
                                 ||| grid
                                 ||| noBorders tabs
                                 -- ||| spirals
                                 -- ||| threeCol
                                 -- ||| threeRow

xmobarEscape :: String -> String
xmobarEscape = concatMap doubleLts
  where
        doubleLts '<' = "<<"
        doubleLts x   = [x]

myWorkspaces :: [String]
myWorkspaces = clickable . (map xmobarEscape)
               -- $ ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
               $ ["1:dev", "2:www", "3:sys", "4:dev2", "5:chat", "6:ide", "7:call","8:doc","9:ssh"]
  where
        clickable l = [ "<action=xdotool key super+" ++ show (n) ++ "> " ++ ws ++ " </action>" |
                      (i,ws) <- zip [1..9] l,
                      let n = i ]

q ~? x  = fmap (x `isInfixOf`) q

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     -- using 'doShift ( myWorkspaces !! 7)' sends program to workspace 8!
     -- I'm doing it this way because otherwise I would have to write out
     -- the full name of my workspaces.
     [
       className=? "Firefox"      --> doShift ( myWorkspaces !! 1 ),
       className=? "Google-chrome"      --> doShift ( myWorkspaces !! 6 )
     , className=? "Brave-browser"      --> doShift ( myWorkspaces !! 1 )
     , (className=? "Brave-browser"  <&&>   (stringProperty "WM_WINDOW_ROLE")=? "pop-up")    -->  doFloat
     , className=?"Microsoft Teams - Preview"--> doShift (myWorkspaces !! 4)
     , title =? "Discord" --> doShift (myWorkspaces !! 4 )
     , title =? "Oracle VM VirtualBox Manager"     --> doFloat
     , className =? "VirtualBox Manager" --> doShift  ( myWorkspaces !! 7 )
     , (className =? "firefox" <&&> resource =? "Dialog") --> doFloat  -- Float Firefox Dialog
     , (title=? "Brave-browser" <&&> resource =? "Dialog") --> doFloat  -- Float Firefox Dialog
     , title=? "PulseEffects" --> doShift (myWorkspaces !! 5)
     , title~? "Figure " --> doFloat
     , title~? "Figure " --> doShift (myWorkspaces !! 5)
     , className=? "Spotify" --> (customFloating $ W.RationalRect 0.5025 0.01 0.4925 0.98)
     ] <+> namedScratchpadManageHook myScratchPads 


myLogHook :: X ()
myLogHook = fadeInactiveLogHook fadeAmount
    where fadeAmount = 1


myKeys :: [(String, X ())]
myKeys =
    -- Xmonad
        [ ("M-C-r", spawn "xmonad --recompile")      -- Recompiles xmonad
        , ("M-S-r", spawn "xmonad --restart")        -- Restarts xmonad
        , ("M-S-q", io exitSuccess)                  -- Quits xmonad
        --, ("M-C-l", spawn "slock")
        , ("M-C-<Del>", spawn "dm-tool lock")


    -- Open my preferred terminal
        , ("M-<Return>", spawn myTerminal)

    -- Windows
        , ("M-S-c", kill1)                           -- Kill the currently focused client
        , ("M-S-a", killAll)                         -- Kill all windows on current workspace
    -- Floating windows
        , ("M-f", sendMessage (T.Toggle "floats"))       -- Toggles my 'floats' layout
        , ("M-n", sendMessage (T.Toggle "tall"))       -- Toggles my 'floats' layout
        , ("M-<Delete>", withFocused $ windows . W.sink) -- Push floating window back to tile
        , ("M-S-<Delete>", sinkAll)                      -- Push ALL floating windows to tile

    -- Windows navigation
        , ("M-m", windows W.focusMaster)     -- Move focus to the master window
        , ("M-j", windows W.focusDown)       -- Move focus to the next window
        , ("M-k", windows W.focusUp)         -- Move focus to the prev window
        --, ("M-S-m", windows W.swapMaster)    -- Swap the focused window and the master window
        , ("M-S-j", windows W.swapDown)      -- Swap focused window with next window
        , ("M-S-k", windows W.swapUp)        -- Swap focused window with prev window
        , ("M-<Backspace>", promote)         -- Moves focused window to master, others maintain order
        , ("M1-S-<Tab>", rotSlavesDown)      -- Rotate all windows except master and keep focus in place
        , ("M1-C-<Tab>", rotAllDown)         -- Rotate all the windows in the current stack
        --, ("M-S-s", windows copyToAll)
        , ("M-C-s", killAllOtherCopies)
        , ("M-S-l", nextWS)
        , ("M-S-h", prevWS)
        -- KB layouts
        , ("M-C-S-d", spawn "setxkbmap dvorak")
        , ("M-C-S-n", spawn "setxkbmap gb")
        -- Layouts
        , ("M-<Tab>", sendMessage NextLayout)                -- Switch to next layout
        , ("M-C-M1-<Up>", sendMessage Arrange)
        , ("M-C-M1-<Down>", sendMessage DeArrange)
        , ("M-<Space>", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts) -- Toggles noborder/full
        , ("M-S-<Space>", sendMessage ToggleStruts)         -- Toggles struts
        , ("M-S-n", sendMessage $ MT.Toggle NOBORDERS)      -- Toggles noborder
        , ("M-S-=", sendMessage (IncMasterN 1))   -- Increase number of clients in master pane
        , ("M-S-/", sendMessage (IncMasterN (-1)))  -- Decrease number of clients in master pane
        , ("M-S-<Up>", increaseLimit)              -- Increase number of windows
        , ("M-S-<Down>", decreaseLimit)                -- Decrease number of windows

        , ("M-h", sendMessage Shrink)                       -- Shrink horiz window width
        , ("M-l", sendMessage Expand)                       -- Expand horiz window width
        , ("M-C-j", sendMessage MirrorShrink)               -- Shrink vert window width
        , ("M-C-k", sendMessage MirrorExpand)               -- Exoand vert window width

    -- Workspaces
        , ("M-.", nextScreen)  -- Switch focus to next monitor
        , ("M-,", prevScreen)  -- Switch focus to prev monitor
        , ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)       -- Shifts focused window to next ws
        , ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)  -- Shifts focused window to prev ws

    -- Scratchpads
        , ("M-C-<Return>", namedScratchpadAction myScratchPads "terminal")
        , ("M-C-m", namedScratchpadAction myScratchPads "spotify")
        , ("M-C-h", namedScratchpadAction myScratchPads "htop")
        , ("M-C-z", namedScratchpadAction myScratchPads "zotero")


    --- My Applications (Super+Alt+Key)
        , ("M-S-w", spawn myBrowser)
        , ("M-S-e", spawn "emacs")
        , ("M-C-<Space>", spawn "dmenu_run -m 0 -l 1")
        , ("M1-<Tab>", spawn "rofi -show window")
        , ("<Print>", spawn "flameshot gui")
        -- , ("<XF86AudioMute>",   spawn "amixer set Master toggle")  -- Bug prevents it from toggling correctly in 12.04.
        , ("<XF86AudioLowerVolume>", spawn "amixer -D pulse sset Master 5%- unmute")
        , ("<XF86AudioRaiseVolume>", spawn "amixer -D pulse sset Master 5%+ unmute")

        , ("<XF86AudioNext>", spawn "/home/sam/applications/spt-check next-song")
        , ("<XF86AudioPrev>", spawn "/home/sam/applications/spt-check prev-song")
        , ("<XF86AudioStop>", spawn "/home/sam/applications/spt-check play-pause")
        ]
        -- The following lines are needed for named scratchpads.
          where nonNSP          = WSIs (return (\ws -> W.tag ws /= "nsp"))

main :: IO ()
main = do
    -- Launching three instances of xmobar on their monitors.
    xmproc0 <- spawnPipe "xmobar   -x 0 /home/sam/.config/xmobar/xmobarrc2"
    xmproc1 <- spawnPipe "xmobar   -x 1 /home/sam/.config/xmobar/xmobarrc0"
    -- the xmonad, ya know...what the WM is named after!
    xmonad $ ewmh def
        { manageHook = ( isFullscreen --> doFullFloat ) <+> myManageHook <+> manageDocks
        -- Run xmonad commands from command line with "xmonadctl command". Commands include:
        -- shrink, expand, next-layout, default-layout, restart-wm, xterm, kill, refresh, run,
        -- focus-up, focus-down, swap-up, swap-down, swap-master, sink, quit-wm. You can run
        -- "xmonadctl 0" to generate full list of commands written to ~/.xsession-errors.
        , handleEventHook    = serverModeEventHookCmd
                               <+> serverModeEventHook
                               <+> serverModeEventHookF "XMONAD_PRINT" (io . putStrLn)
                               <+> docksEventHook
                               <+> fullscreenEventHook
                               <+> dynamicPropertyChange "WM_NAME" (className =? "Spotify" --> (customFloating $ W.RationalRect 0.05 0.05 0.9 0.9)) --Annoyign hack to get spotify scratchpad to float.
        , modMask            = myModMask
        , terminal           = myTerminal
        , startupHook        = myStartupHook
        , layoutHook         = myLayoutHook
        , workspaces         = myWorkspaces
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormColor
        , focusedBorderColor = myFocusColor
        , logHook = workspaceHistoryHook <+> myLogHook <+> dynamicLogWithPP xmobarPP
                        { ppOutput = \x -> hPutStrLn xmproc0 x >> hPutStrLn xmproc1 x 
                        , ppCurrent = xmobarColor "#c3e88d" "" . wrap "[" "]" -- Current workspace in xmobar
                        , ppVisible = xmobarColor "#c3e88d" ""                -- Visible but not current workspace
                        , ppHidden = xmobarColor "#82AAFF" "" . wrap "*" ""   -- Hidden workspaces in xmobar
                        , ppHiddenNoWindows = xmobarColor "#c792ea" ""        -- Hidden workspaces (no windows)
                        , ppTitle = xmobarColor "#b3afc2" "" . shorten 60     -- Title of active window in xmobar
                        , ppSep =  "<fc=#666666> <fn=2>|</fn> </fc>"                     -- Separators in xmobar
                        , ppUrgent = xmobarColor "#C45500" "" . wrap "!" "!"  -- Urgent workspace
                        , ppExtras  = [windowCount]                           -- # of windows current workspace
                        , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]
                        }
        } `additionalKeysP` myKeys
