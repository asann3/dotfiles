import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Layout.Spacing
import XMonad.Layout.ThreeColumns
import XMonad.Util.EZConfig (additionalKeys, removeKeys)
import XMonad.Util.SpawnOnce (spawnOnce)
import qualified XMonad.StackSet as W
import qualified Data.Map as M

myMod :: KeyMask
myMod = mod4Mask

main :: IO ()
main = xmonad . docks . withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) defToggleStrutsKey
     $ myConfig
       `removeKeys` defaultConflicts
       `additionalKeys` myKeys

myConfig = def
  { modMask            = myMod
  , terminal           = "gnome-terminal"
  , layoutHook         = myLayout
  , startupHook        = myStartupHook
  , mouseBindings      = myMouseBindings
  , borderWidth        = 2
  , normalBorderColor  = "#3b4252"
  , focusedBorderColor = "#88c0d0"
  }

myKeys :: [((KeyMask, KeySym), X ())]
myKeys =
  [ ((myMod .|. shiftMask, xK_Return), spawn "gnome-terminal")
  , ((myMod .|. shiftMask, xK_space),  sendMessage NextLayout)
  , ((myMod .|. shiftMask, xK_j),      windows W.focusDown)
  , ((myMod .|. shiftMask, xK_k),      windows W.focusUp)
  , ((myMod .|. shiftMask, xK_h),      sendMessage Shrink)
  , ((myMod .|. shiftMask, xK_l),      sendMessage Expand)
  , ((myMod .|. shiftMask, xK_c),      kill)
  , ((myMod .|. shiftMask, xK_q),      kill)
  , ((myMod,               xK_l),      spawn "xscreensaver-command -lock")
  ]
  ++
  [ ((myMod .|. shiftMask, k), windows (W.greedyView ws))
  | (ws, k) <- zip (XMonad.workspaces myConfig) [xK_1 .. xK_9]
  ]

defaultConflicts :: [(KeyMask, KeySym)]
defaultConflicts =
  [ (myMod,               xK_Return)
  , (myMod,               xK_space)
  , (myMod .|. shiftMask, xK_Return)
  , (myMod .|. shiftMask, xK_space)
  , (myMod .|. shiftMask, xK_c)
  ]

myXmobarPP :: PP
myXmobarPP = def
  { ppCurrent         = xmobarColor "#88c0d0" "" . wrap "[" "]"
  , ppHidden          = xmobarColor "#81a1c1" ""
  , ppHiddenNoWindows = xmobarColor "#4c566a" ""
  , ppTitle           = xmobarColor "#a3be8c" "" . shorten 60
  , ppSep             = "  |  "
  }

myLayout = avoidStruts . spacingRaw False (Border 5 5 5 5) True (Border 5 5 5 5) True $
  tall ||| wide ||| Full ||| column
  where
    tall   = Tall 1 (3/100) (1/2)
    wide   = Mirror (Tall 1 (3/100) (1/2))
    column = ThreeColMid 1 (3/100) (1/2)

myStartupHook :: X ()
myStartupHook = do
  spawnOnce "xscreensaver -no-splash"
  spawnOnce "dbus-update-activation-environment --systemd DISPLAY XAUTHORITY"
  spawnOnce "nm-applet"
  spawnOnce "xsetroot -cursor_name left_ptr"
  spawnOnce "ibus-daemon --xim --replace -d && sleep 2 && ibus engine mozc-us"
  spawnOnce "gnome-terminal"

myMouseBindings :: XConfig Layout -> M.Map (KeyMask, Button) (Window -> X ())
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList
  [ ((modm, button1), \w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster)
  , ((modm, button3), \w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster)
  ]
