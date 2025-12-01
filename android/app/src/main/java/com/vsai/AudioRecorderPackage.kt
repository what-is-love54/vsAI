package com.vsai

import com.vsai.AudioRecorderModule
import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class AudioRecorderPackage : TurboReactPackage() {

    override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
        return if (name == AudioRecorderModule.Companion.NAME) {
            AudioRecorderModule(reactContext)
        } else {
            null
        }
    }

    override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
        return ReactModuleInfoProvider {
            val moduleInfos: MutableMap<String, ReactModuleInfo> = HashMap()
            moduleInfos[AudioRecorderModule.Companion.NAME] = ReactModuleInfo(
                AudioRecorderModule.Companion.NAME,
                AudioRecorderModule.Companion.NAME,
                false,  // canOverrideExistingModule
                false,  // needsEagerInit
                true,   // hasConstants
                false,  // isCxxModule
                true    // isTurboModule
            )
            moduleInfos
        }
    }
}