#SingleInstance,force
#Persistent
#Include uia.ahk
CoordMode,mouse,screen
global $n:={} ; store tree node
,$u:=new IUIAutomation
,$e:=new IUIAutomationElement
,$c:=new IUIAutomationCondition
,$r:=new IUIAutomationCacheRequest
,$t:=new IUIAutomationTreeWalker

global $x:=ComObjCreate("MSXML2.DOMDocument")
$x.setProperty("SelectionLanguage","XPath")
gui,1:add,TreeView,w300 h600 gtvevent
gui,1:add,tab2,X+5 yp w500 +0x100,% "  Info  |  Pool  |  Tree2Xml  |  Xml2AHK  |  Settings  |  Help  "
gui,1:tab,1
gui,1:add,edit,w500 h580 X+0 Y+0 vedit1 ReadOnly -wrap HScroll
return

F8::
	MouseGetPos,x,y,hwnd
	BuildElementTree(hwnd)
	gui,1:show
	return

tvevent:
	if A_GuiEvent = S
		ShowSelection(TV_GetSelection())
	return

BuildElementTree(hwnd){
	static init:=1,root,_r
	if init{
		init:=0, root:=$u.GetRootElement(), $r.(_r:=$u.CreateCacheRequest()).TreeScope:=UIA_Enum("TreeScope_Subtree"), t:={}
		loop 111
			t.Insert(29999+A_Index)		;Array to contain UIA_Properties
		$r.AddProperty(t)
	}
	for k,v in $n
		ObjRelease(v)
	$n:={},	TV_Delete()
	;msgbox, % hwnd
	_e:=$u.ElementFromHandleBuildCache(hwnd,_r)
	;msgbox, % """" . $e.(_e).CachedName() . """"
	if (!_e){
		msgbox, An error occurred while getting element. Reloading application...
		reload
	}
	if $u.CompareElements(_e,root)
		return	;Do nothing if F8 while desktop selected ; ToDo: EventBased cache search
	$n[id:=TV_Add($e.(_e).CachedName())]:=_e
	,((type:=$e.GetCachedPropertyValue(UIA_Property("ControlType")))=UIA_ControlType("Menu"))||(type=UIA_ControlType("ToolBar"))?AddNode(_e,id,1):AddNode(_e,id)	
	; AddChildren(_e,id)
}
AddNode(element,id,mode=0){
	static init:=1,_r,_t
	if init{
		init:=0,$t.(_t:=$u.RawViewWalker()),$r.(_r:=$u.CreateCacheRequest()).TreeScope:=1, t:={}
		loop 111
			t.Insert(29999+A_Index)
		$r.3(t)
	}
	if mode{
		if (newElement:=$t.GetCurrentPropertyValue(element,_r)){
			$n[newId:=TV_Add("""" $e.(newElement).CachedName() """ " $e.CachedLocalizedControlType(),id)]:=newElement
			,((type:=$e.GetCachedPropertyValue(UIA_Property("ControlType")))=UIA_ControlType("Menu"))||(type=UIA_ControlType("ToolBar"))?AddNode(newElement,newId,1):AddNode(newElement,newId)
			loop
				if (newElement:=$t.GetCachedPropertyValue(newElement,_r))
					$n[newId:=TV_Add("""" $e.(newElement).CachedName() """ " $e.CachedLocalizedControlType(),id)]:=newElement
					,((type:=$e.GetCachedPropertyValue(UIA_Property("ControlType")))=UIA_ControlType("Menu"))||(type=UIA_ControlType("ToolBar"))?AddNode(newElement,newId,1):AddNode(newElement,newId)	
				else break
		}
	}else{
		if !array:=$e.(element).GetCachedChildren()
			return
		loop % $e.(array).length()
			$n[newId:=TV_Add("""" $e.(newElement:=$e.(array).element(A_Index-1)).CachedName() """ " $e.CachedLocalizedControlType(),id)]:=newElement
			,((type:=$e.GetCachedPropertyValue(UIA_Property("ControlType")))=UIA_ControlType("Menu"))||(type=UIA_ControlType("ToolBar"))?AddNode(newElement,newId,1):AddNode(newElement,newId)	
		ObjRelease(array)
	}
}
AddChildren(element,id){
	if !array:=$e.(element).GetCachedChildren()
		return
	loop % $e.(array).length()
		$n[newId:=TV_Add("""" $e.(newElement:=$e.(array).element(A_Index-1)).CachedName() """ " $e.CachedLocalizedControlType(),id)]:=newElement
		,AddChildren(newElement,newId)
	ObjRelease(array)
}
AddRawNode(e,id,pid){ ; RawTreeWalker, slow speed
	static init:=1,_r,_t
	if init{
		init:=0,$t.(_t:=$u.RawViewWalker()),$r.(_r:=$u.CreateCacheRequest()).TreeScope:=UIA_Enum("TreeScope_Element"), t:={}
		loop 111
			t.Insert(29999+A_Index)
		$r.AddProperty(t)
	}
	if ne:=$t.GetCurrentPropertyValue(e,_r){
		$n[nid:=TV_Add("""" $e.(ne).CachedName() """ " $e.CachedLocalizedControlType(),id)]:=ne
		AddRawNode(ne,nid,id)
	}
	if (pid!=0) && (ne:=$t.GetCachedPropertyValue(e,_r)){
		$n[nid:=TV_Add("""" $e.(ne).CachedName() """ " $e.CachedLocalizedControlType(),pid)]:=ne
		AddRawNode(ne,nid,pid)
	}
}
ShowSelection(id){
	global edit1
	$e.($n[id])	;								UIA_Property("")
	cont:="Name:                               " $e.GetCachedPropertyValue(UIA_Property("Name")) 										"`n" 
		. "ControlType:                        " UIA_ControlType($e.GetCachedPropertyValue(UIA_Property("ControlType"))) 				"`n" ;
		. "LocalizedControlType:               " $e.GetCachedPropertyValue(UIA_Property("LocalizedControlType")) 						"`n" ;
		. "BoundingRectangle:                  " BoundingRectangle($e.GetCachedPropertyValue(UIA_Property("BoundingRectangle"))) 		"`n" ;
		. "IsEnabled:                          " Bool($e.GetCachedPropertyValue(UIA_Property("IsEnabled"))) 							"`n" ;
		. "IsOffscreen:                        " Bool($e.GetCachedPropertyValue(UIA_Property("IsOffscreen"))) 							"`n" ;
		. "IsKeyboardFocusable:                " Bool($e.GetCachedPropertyValue(UIA_Property("IsKeyboardFocusable"))) 					"`n" ;
		. "HasKeyboardFocus:                   " Bool($e.GetCachedPropertyValue(UIA_Property("HasKeyboardFocus"))) 						"`n" ;
		. "AccessKey:                          " $e.GetCachedPropertyValue(UIA_Property("AccessKey")) 									"`n" ;
		. "ProcessId:                          " $e.GetCachedPropertyValue(UIA_Property("ProcessId")) 									"`n" ;
		. "RuntimeId:                          " RuntimeId($e.GetCachedPropertyValue(UIA_Property("RuntimeId"))) 						"`n" ;
		. "AutomationId:                       " $e.GetCachedPropertyValue(UIA_Property("AutomationId")) 								"`n" ;
		. "FrameworkId:                        " $e.GetCachedPropertyValue(UIA_Property("FrameworkId")) 								"`n" ;
		. "ClassName:                          " $e.GetCachedPropertyValue(UIA_Property("ClassName")) 									"`n" ;
		. "NativeWindowHandle:                 " $e.GetCachedPropertyValue(UIA_Property("NativeWindowHandle")) 							"`n" ;
		. "IsContentElement:                   " Bool($e.GetCachedPropertyValue(UIA_Property("IsContentElement"))) 						"`n" ;
		. "ProviderDescription:                " $e.GetCachedPropertyValue(UIA_Property("IsContentElement")) 							"`n" ;
		. "IsPassword:                         " Bool($e.GetCachedPropertyValue(UIA_Property("IsPassword"))) 							"`n" ;
		. "HelpText:                           " $e.GetCachedPropertyValue(UIA_Property("HelpText")) 									"`n" ; 
	cont.="IsDockPatternAvailable:             " Bool($e.GetCachedPropertyValue(UIA_Property("IsDockPatternAvailable"))) 				"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsDockPatternAvailable"))?		  "DockDockPosition:                   " $e.GetCachedPropertyValue(UIA_Property("DockDockPosition")) "`n" :"" ;
	cont.="IsExpandCollapsePatternAvailable:   " Bool($e.GetCachedPropertyValue(UIA_Property("IsExpandCollapsePatternAvailable")))		"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsExpandCollapsePatternAvailable"))?"ExpandCollapseExpandCollapseState:  " $e.GetCachedPropertyValue(UIA_Property("ExpandCollapseExpandCollapseState")) "`n" :"" ;
	cont.="IsGridItemPatternAvailable:         " Bool($e.GetCachedPropertyValue(UIA_Property("IsGridItemPatternAvailable")))			"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsGridItemPatternAvailable"))? getGridPattern($e):""
	cont.="IsGridPatternAvailable:             " Bool($e.GetCachedPropertyValue(UIA_Property("IsGridPatternAvailable")))				"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsGridPatternAvailable"))? getGridPattern($e) : "" 
	cont.="IsInvokePatternAvailable:           " Bool($e.GetCachedPropertyValue(UIA_Property("IsInvokePatternAvailable")))				"`n" ;
	cont.="IsItemContainerPatternAvailable:    " Bool($e.GetCachedPropertyValue(UIA_Property("IsItemContainerPatternAvailable")))		"`n" ;
	cont.="IsLegacyIAccessiblePatternAvailable:" Bool($e.GetCachedPropertyValue(UIA_Property("IsLegacyIAccessiblePatternAvailable"))) 	"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsLegacyIAccessiblePatternAvailable"))? getLegacyPattern($e) : "" 
	cont.="IsMultipleViewPatternAvailable:     " Bool($e.GetCachedPropertyValue(UIA_Property("IsMultipleViewPatternAvailable")))		"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsMultipleViewPatternAvailable"))? getMultiviewPattern($e) : "" 
	cont.="IsRangeValuePatternAvailable:       " Bool($e.GetCachedPropertyValue(UIA_Property("IsRangeValuePatternAvailable")))			"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsRangeValuePatternAvailable"))? getRangePattern($e) : "" 
	cont.="IsScrollItemPatternAvailable:       " Bool($e.GetCachedPropertyValue(UIA_Property("IsScrollItemPatternAvailable")))			"`n" ;
	cont.="IsScrollPatternAvailable:           " Bool($e.GetCachedPropertyValue(UIA_Property("IsScrollPatternAvailable")))				"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsScrollPatternAvailable"))? getScrollPattern($e) : "" 
	cont.="IsSelectionItemPatternAvailable:    " Bool($e.GetCachedPropertyValue(UIA_Property("IsSelectionItemPatternAvailable")))		"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsSelectionItemPatternAvailable"))? getSelectionItemPattern($e) : "" 
	cont.="IsSelectionPatternAvailable:        " Bool($e.GetCachedPropertyValue(UIA_Property("IsSelectionPatternAvailable")))			"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsSelectionPatternAvailable"))? getSelectionPattern($e) : "" 
	cont.="IsSynchronizedInputPatternAvailable:" Bool($e.GetCachedPropertyValue(UIA_Property("IsSynchronizedInputPatternAvailable"))) 	"`n" ;
	cont.="IsTablePatternAvailable:            " Bool($e.GetCachedPropertyValue(UIA_Property("IsTablePatternAvailable")))				"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsTablePatternAvailable"))? getTablePattern($e) : "" 
	cont.="IsTextPatternAvailable:             " Bool($e.GetCachedPropertyValue(UIA_Property("IsTextPatternAvailable")))				"`n" ;
	cont.="IsTogglePatternAvailable:           " Bool($e.GetCachedPropertyValue(UIA_Property("IsTogglePatternAvailable")))				"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsTogglePatternAvailable"))? getTogglePattern($e) : "" 
	cont.="IsTransformPatternAvailable:        " Bool($e.GetCachedPropertyValue(UIA_Property("IsTransformPatternAvailable")))			"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsTransformPatternAvailable"))? getTransformPattern($e) : "" 
	cont.="IsValuePatternAvailable:            " Bool($e.GetCachedPropertyValue(UIA_Property("IsValuePatternAvailable")))				"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsValuePatternAvailable"))? getValuePattern($e) : "" 
	cont.="IsVirtualizedItemPatternAvailable:  " Bool($e.GetCachedPropertyValue(UIA_Property("IsVirtualizedItemPatternAvailable")))		"`n" ;
	cont.="IsWindowPatternAvailable:           " Bool($e.GetCachedPropertyValue(UIA_Property("IsWindowPatternAvailable")))				"`n" ;
	cont.=$e.GetCachedPropertyValue(UIA_Property("IsWindowPatternAvailable"))?getWindowPattern($e): ""
	GuiControl,1:,edit1,% cont
}

getGridItemPattern($e){
cont:="GridItemRow:                        " $e.GetCachedPropertyValue(UIA_Property("GridItemRow"))							"`n"
    . "GridItemColumn:                     " $e.GetCachedPropertyValue(UIA_Property("GridItemColumn"))						"`n"
	. "GridItemRowSpan:                    " $e.GetCachedPropertyValue(UIA_Property("GridItemRowSpan"))						"`n"
	. "GridItemColumnSpan:                 " $e.GetCachedPropertyValue(UIA_Property("GridItemColumnSpan"))					"`n"
	. "GridItemContainingGrid:             " $e.GetCachedPropertyValue(UIA_Property("GridItemContainingGrid"))				"`n"
	return cont 
}
getGridPattern($e){
cont:="GridRowCount:                       " $e.GetCachedPropertyValue(UIA_Property("GridRowCount"))						"`n"
    . "GridColumnCount:                    " $e.GetCachedPropertyValue(UIA_Property("GridColumnCount"))						"`n"
	return cont
}

getLegacyPattern($e){
cont:="LegacyIAccessibleChildId:           " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleChildId"))			"`n"
	. "LegacyIAccessibleName:              " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleName"))				"`n"
	. "LegacyIAccessibleValue:             " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleValue"))				"`n"
	. "LegacyIAccessibleDescription:       " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleDescription")) 		"`n"
	. "LegacyIAccessibleRole:              " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleRole"))				"`n"
	. "LegacyIAccessibleState:             " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleState"))				"`n"
	. "LegacyIAccessibleHelp:              " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleHelp"))				"`n"
	. "LegacyIAccessibleKeyboardShortcut:  " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleKeyboardShortcut"))	"`n"
	. "LegacyIAccessibleSelection:         " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleSelection"))			"`n"
	. "LegacyIAccessibleDefaultAction:     " $e.GetCachedPropertyValue(UIA_Property("LegacyIAccessibleDefaultAction"))		"`n" 
	return cont	
}	
	
getMultiviewPattern($e){	
cont:="MultipleViewCurrentView:            " $e.GetCachedPropertyValue(UIA_Property("MultipleViewCurrentView"))				"`n"
    . "MultipleViewSupportedViews:         " $e.GetCachedPropertyValue(UIA_Property("MultipleViewSupportedViews"))			"`n"
	return cont	
}	
	
getRangePattern($e){	
cont:="RangeValueValue:                    " $e.GetCachedPropertyValue(UIA_Property("RangeValueValue"))						"`n"
	. "RangeValueIsReadOnly:               " $e.GetCachedPropertyValue(UIA_Property("RangeValueIsReadOnly"))				"`n"
	. "RangeValueMinimum:                  " $e.GetCachedPropertyValue(UIA_Property("RangeValueMinimum"))					"`n"
	. "RangeValueMaximum:                  " $e.GetCachedPropertyValue(UIA_Property("RangeValueMaximum"))					"`n"
	. "RangeValueLargeChange:              " $e.GetCachedPropertyValue(UIA_Property("RangeValueLargeChange"))				"`n"
	. "RangeValueSmallChange:              " $e.GetCachedPropertyValue(UIA_Property("RangeValueSmallChange"))				"`n" 
	return cont	
}	
	
getScrollPattern($e){	
cont:="ScrollHorizontalScrollPercent:      " $e.GetCachedPropertyValue(UIA_Property("ScrollHorizontalScrollPercent"))		"`n"
	. "ScrollHorizontalViewSize:           " $e.GetCachedPropertyValue(UIA_Property("ScrollHorizontalViewSize"))			"`n"
	. "ScrollVerticalScrollPercent:        " $e.GetCachedPropertyValue(UIA_Property("ScrollVerticalScrollPercent"))			"`n"
	. "ScrollVerticalViewSize:             " $e.GetCachedPropertyValue(UIA_Property("ScrollVerticalViewSize"))				"`n"
	. "ScrollHorizontallyScrollable:       " $e.GetCachedPropertyValue(UIA_Property("ScrollHorizontallyScrollable"))		"`n"
	. "ScrollVerticallyScrollable:         " $e.GetCachedPropertyValue(UIA_Property("ScrollVerticallyScrollable"))			"`n" 
	return cont	
}	
	
getSelectionItemPattern($e){	
cont:="SelectionItemIsSelected:            " $e.GetCachedPropertyValue(UIA_Property("SelectionItemIsSelected"))				"`n"
    . "SelectionItemSelectionContainer:    " $e.GetCachedPropertyValue(UIA_Property("SelectionItemSelectionContainer"))		"`n"
	return cont	
}	
	
getSelectionPattern($e){	
cont:="SelectionSelection:                 " $e.GetCachedPropertyValue(UIA_Property("SelectionSelection"))					"`n"
	. "SelectionCanSelectMultiple:         " $e.GetCachedPropertyValue(UIA_Property("SelectionCanSelectMultiple"))			"`n"
    . "SelectionIsSelectionRequired:       " $e.GetCachedPropertyValue(UIA_Property("SelectionIsSelectionRequired"))		"`n"
	return cont	
}	
	
getTablePattern($e){	
cont:="TableRowHeaders:                    " $e.GetCachedPropertyValue(UIA_Property("TableRowHeaders"))						"`n"
	. "TableColumnHeaders:                 " $e.GetCachedPropertyValue(UIA_Property("TableColumnHeaders"))					"`n"
	. "TableRowOrColumnMajor:              " $e.GetCachedPropertyValue(UIA_Property("TableRowOrColumnMajor"))				"`n"
	. "TableItemRowHeaderItems:            " $e.GetCachedPropertyValue(UIA_Property("TableItemRowHeaderItems"))				"`n"
	. "TableItemColumnHeaderItems:         " $e.GetCachedPropertyValue(UIA_Property("TableItemColumnHeaderItems"))			"`n"
	return cont	
}	
	
getTogglePattern($e){	
cont:="ToggleToggleState:                  " $e.GetCachedPropertyValue(UIA_Property("ToggleToggleState"))					"`n"
	return cont	
}	
	
getTransformPattern($e){	
cont:="TransformCanMove:                   " Bool($e.GetCachedPropertyValue(UIA_Property("TransformCanMove")))				"`n"
	. "TransformCanResize:                 " Bool($e.GetCachedPropertyValue(UIA_Property("TransformCanResize")))			"`n"
    . "TransformCanRotate:                 " Bool($e.GetCachedPropertyValue(UIA_Property("TransformCanRotate")))			"`n"
	return cont	
}	
	
getValuePattern($e){	
cont:="ValueValue:                         " $e.GetCachedPropertyValue(UIA_Property("ValueValue"))							"`n"
    . "ValueIsReadOnly:                    " Bool($e.GetCachedPropertyValue(UIA_Property("ValueIsReadOnly")))				"`n"
	return cont
}

getWindowPattern($e){
cont:="WindowCanMaximize:                  " Bool($e.GetCachedPropertyValue(UIA_Property("WindowCanMaximize")))				"`n"
	. "WindowCanMinimize:                  " Bool($e.GetCachedPropertyValue(UIA_Property("WindowCanMinimize")))				"`n"
	. "WindowWindowVisualState:            " $e.GetCachedPropertyValue(UIA_Property("WindowWindowVisualState"))				"`n"
	. "WindowWindowInteractionState:       " $e.GetCachedPropertyValue(UIA_Property("WindowWindowInteractionState"))		"`n"
	. "WindowIsModal:                      " Bool($e.GetCachedPropertyValue(UIA_Property("WindowIsModal")))					"`n"
	. "WindowIsTopmost:                    " Bool($e.GetCachedPropertyValue(UIA_Property("WindowIsTopmost")))				"`n" 
	return cont
}

;;
;;Output Function
;;
RuntimeId(p){
	SetFormat,integer,hex
	VarSetCapacity(a,4)
	for k,v in p
		NumPut(v,a,"int")
		,s.=SubStr(NumGet(a,"uint"),3) "."
	StringTrimRight,s,s,1
	SetFormat,integer,d
	return s
}
BoundingRectangle(t){
	return (IsObject(t)?"l:" SubStr(t.1,1,InStr(t.1,".")-1) " t:" SubStr(t.2,1,InStr(t.2,".")-1) " w:" SubStr(t.3,1,InStr(t.3,".")-1) " h:" SubStr(t.4,1,InStr(t.4,".")-1):)
}
Bool(b){
	return b?"True":"False"
}
;;
;;Tree Functions
;;
AnalysisTree(id){
	$x.loadxml("")
	AnalysisNode(id)
}
AnalysisNode(id){
	; check Control Type
	if !newId:=TV_GetChild(id)
		return
	loop {
		ct:=$e.($n[newId]).GetCachedPropertyValue(30003)
		if (ct=50000){ ;Button
			
		}else if (ct=50001){ ;Calendar
		
		}else if (ct=50002){ ;CheckBox
		
		}else if (ct=50003){ ;ComboBox
		
		}else if (ct=50004){ ;Edit
			
		}else if (ct=50005){ ;link
		
		}else if (ct=50006){ ;Image
		
		}else if (ct=50007){ ;ListItem
		
		}else if (ct=50008){ ;ListView
		
		}else if (ct=50009){ ;Menu
		
		}else if (ct=50010){ ;MenuBar
			GetMenuBar(newId)
		}else if (ct=50011){ ;MenuItem
		
		}else if (ct=50012){ ;ProgressBar
		
		}else if (ct=50013){ ;Radio
		
		}else if (ct=50017){ ;StatusBar
		
		}else if (ct=50018){ ;Tab
		
		}else if (ct=50019){ ;Tab Item
		
		}else if (ct=50020){ ;Text
		
		}else if (ct=50021){ ;ToolBar
		
		}else if (ct=50023){ ;TreeView
		
		}else if (ct=50032){ ;Window
		
		}else if (ct=50033){ ;pane
		
		}else if (ct=50034){ ;Header
		
		}else if (ct=50035){ ;HeaderItem
		
		}else if (ct=50037){ ;TitleBar
		
		}else{
			
		}
		
		if !newId:=TV_GetNext(newId)
			break
	}
}

Winget(id){
	if !hwnd:=$e.($n[id]).GetCachedPropertyValue(30020)
		return 
	SetFormat,integer,hex
	WinGet,style,style,ahk_id %hwnd%
	WinGet,exstyle,exstyle,ahk_id %hwnd%
	WinGetClass,class,ahk_id %hwnd%
	SetFormat,integer,d
	return {hwnd:hwnd,class:class,style:style,exstyle:exstyle}
}

GetMenuBar(id){
	
}
;;
;;xml to AHK code
;;
xml2ahk(){
	
}
