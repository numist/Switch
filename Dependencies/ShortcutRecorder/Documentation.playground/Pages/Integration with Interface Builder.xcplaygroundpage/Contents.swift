//: [Previous](@previous)
/*:
 ## Interface Builder Integration
 `RecorderControl` and `ShortcutAction` can be configured entirely in Xcode's Interface Builder.

 1. Locate Custom View in the Objects Library and add it to Canvas\
    ![Add View](Step1.heic)
 2. Change class of the just added Custom View to `SRRecorderControl`\
    ![Change View Class](Step2.heic)
 3. Switch to the Size inspector and add placeholder for intrinsic content size\
    ![Set Intrinsic Content Size](Step3.heic)
 - Note:
 It's only a placeholder, the control will use correct size inherited from its style in runtime.
 4. Locate `NSObjectController` in the Objects Library and add it to Canvas\
    ![Add NSObjectController](Step4.heic)
 5. Change class of the just added `NSObjectController` to `SRShortcutController`\
    ![Change Controller Class](Step5.heic)
 6. Switch to the Attributes inspector and set content's class to `SRShortcut`\
    ![Change Controller's Content Class](Step6.heic)
 7. Switch to the Bindings inspector and configure the Content Object binding\
    ![Set Controller's Content Object binding](Step7.heic)
 - Important:
 In this example content is bound to the Shared User Defaults controller.
 It is therefore necessary to use the `NSKeyedUnarchiveFromData` transformer to store `SRShortcut` inside a plist.
 8. Switch to the Connections inspector and configure the `recorderControl` connection by pointing it to the view
    and the `shortcutActionTarget` connection to the object that implements the `SRShortcutActionTarget`
    protocol (in this example it is File Owner)\
    ![Set Controller's Connections](Step8.heic)

 Now, whenever you record a shortcut with the control, it will be saved into user's defaults.
 The system-wide shortcut action targeting File Owner will be updated accordingly.
 */
//: [Next](@next)
