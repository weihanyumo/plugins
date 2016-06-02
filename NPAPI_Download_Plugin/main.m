//
//  main.m
//  NPAPI_Download_Plugin
//
// Created by TanHao on 13-2-22.
// Copyright (c) 2012年 http://www.tanhao.me. All rights reserved.

#import <WebKit/npapi.h>
#import <WebKit/npfunctions.h>
#import <WebKit/npruntime.h>

#import <QuartzCore/QuartzCore.h>
#import "DownloadWindowController.h"

// Browser function table
// 可以通过它来得到浏览器提供的功能
NPNetscapeFuncs* browser;

// Structure for per-instance storage
// 每个实例存储结构
typedef struct PluginObject
{
    NPP npp;
    NPWindow window;
    DownloadWindowController *dwc;
} PluginObject;

////////////////////////////////////
/*******各种接口的声明*********/
//在NPAPI编程的接口中你会发现有NP_打头的，有NPP_打头的，有NPN_打头的
//NP是npapi的插件库提供给浏览器的最上层的接口
//NPP即NP Plugin是插件本身提供给浏览器调用的接口，主要被用来填充NPPluginFuncs的结构体
//NPN即NP Netscape ,是浏览器提供给插件使用的接口，这些接口一般都在NPNetscapeFuncs结构体中

NPError NPP_New(NPMIMEType pluginType, NPP instance, uint16_t mode, int16_t argc, char* argn[], char* argv[], NPSavedData* saved);
NPError NPP_Destroy(NPP instance, NPSavedData** save);
NPError NPP_SetWindow(NPP instance, NPWindow* window);
NPError NPP_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype);
NPError NPP_DestroyStream(NPP instance, NPStream* stream, NPReason reason);
int32_t NPP_WriteReady(NPP instance, NPStream* stream);
int32_t NPP_Write(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer);
void NPP_StreamAsFile(NPP instance, NPStream* stream, const char* fname);
void NPP_Print(NPP instance, NPPrint* platformPrint);
int16_t NPP_HandleEvent(NPP instance, void* event);
void NPP_URLNotify(NPP instance, const char* URL, NPReason reason, void* notifyData);
NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value);
NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value);

//#pragma export on
// Mach-o entry points 浏览器和创建交流的最上层的接口
NPError NP_Initialize(NPNetscapeFuncs *browserFuncs);
NPError NP_GetEntryPoints(NPPluginFuncs *pluginFuncs);
void NP_Shutdown(void);
//#pragma export off

//通过此方法将浏览器的对象返回给插件
NPError NP_Initialize(NPNetscapeFuncs* browserFuncs)
{
    browser = browserFuncs;
    return NPERR_NO_ERROR;
}

//通过此方法将插件的接口返回给浏览器(填充NPPluginFuncs结构体中的方法指针，让浏览器可以调用本插件)
NPError NP_GetEntryPoints(NPPluginFuncs* pluginFuncs)
{
    pluginFuncs->version = 11;
    pluginFuncs->size = sizeof(pluginFuncs);
    pluginFuncs->newp = NPP_New;
    pluginFuncs->destroy = NPP_Destroy;
    pluginFuncs->setwindow = NPP_SetWindow;
    pluginFuncs->newstream = NPP_NewStream;
    pluginFuncs->destroystream = NPP_DestroyStream;
    pluginFuncs->asfile = NPP_StreamAsFile;
    pluginFuncs->writeready = NPP_WriteReady;
    pluginFuncs->write = (NPP_WriteProcPtr)NPP_Write;
    pluginFuncs->print = NPP_Print;
    pluginFuncs->event = NPP_HandleEvent;
    pluginFuncs->urlnotify = NPP_URLNotify;
    pluginFuncs->getvalue = NPP_GetValue;
    pluginFuncs->setvalue = NPP_SetValue;
    
    return NPERR_NO_ERROR;
}

void NP_Shutdown(void)
{

}

NPError NPP_New(NPMIMEType pluginType, NPP instance, uint16_t mode, int16_t argc, char* argn[], char* argv[], NPSavedData* saved)
{
    // Create per-instance storage
    PluginObject *obj = (PluginObject *)malloc(sizeof(PluginObject));
    bzero(obj, sizeof(PluginObject));
    
    obj->npp = instance;
    instance->pdata = obj;
    
    obj->dwc = [[DownloadWindowController alloc] init];
    
    // Ask the browser if it supports the Core Animation drawing model
    NPBool supportsCoreAnimation;
    if (browser->getvalue(instance, NPNVsupportsCoreAnimationBool, &supportsCoreAnimation) != NPERR_NO_ERROR)
        supportsCoreAnimation = FALSE;
    
    if (!supportsCoreAnimation)
        return NPERR_INCOMPATIBLE_VERSION_ERROR;
    
    // If the browser supports the Core Animation drawing model, enable it.
    browser->setvalue(instance, NPPVpluginDrawingModel, (void *)NPDrawingModelCoreAnimation);

    // If the browser supports the Cocoa event model, enable it.
    NPBool supportsCocoa;
    if (browser->getvalue(instance, NPNVsupportsCocoaBool, &supportsCocoa) != NPERR_NO_ERROR)
        supportsCocoa = FALSE;
    
    if (!supportsCocoa)
        return NPERR_INCOMPATIBLE_VERSION_ERROR;
    
    browser->setvalue(instance, NPPVpluginEventModel, (void *)NPEventModelCocoa);
    
    for (int16_t i = 0; i < argc; i++) {
        
        NSLog(@"argn:%@",[NSString stringWithUTF8String:argn[i]]);
        NSLog(@"argv:%@",[NSString stringWithUTF8String:argv[i]]);
        
        if (strcasecmp(argn[i], "src") == 0) {
            NSString *urlString = [NSString stringWithUTF8String:argv[i]];
            if (urlString)
            {
                [obj->dwc setUrl:[NSURL URLWithString:urlString]];
            }
            break;
        }
        
    }
    
    return NPERR_NO_ERROR;
}

NPError NPP_Destroy(NPP instance, NPSavedData** save)
{
    PluginObject *obj = instance->pdata;

    [obj->dwc release];
    
    free(obj);
    
    return NPERR_NO_ERROR;
}

NPError NPP_SetWindow(NPP instance, NPWindow* window)
{
    PluginObject *obj = instance->pdata;
    obj->window = *window;

    return NPERR_NO_ERROR;
}
 

NPError NPP_NewStream(NPP instance, NPMIMEType type, NPStream* stream, NPBool seekable, uint16* stype)
{
    *stype = NP_ASFILEONLY;
    return NPERR_NO_ERROR;
}

NPError NPP_DestroyStream(NPP instance, NPStream* stream, NPReason reason)
{
    return NPERR_NO_ERROR;
}

int32_t NPP_WriteReady(NPP instance, NPStream* stream)
{
    return 0;
}

int32_t NPP_Write(NPP instance, NPStream* stream, int32_t offset, int32_t len, void* buffer)
{
    return 0;
}

void NPP_StreamAsFile(NPP instance, NPStream* stream, const char* fname)
{
}

void NPP_Print(NPP instance, NPPrint* platformPrint)
{

}

int16_t NPP_HandleEvent(NPP instance, void* event)
{
    return 0;
}

void NPP_URLNotify(NPP instance, const char* url, NPReason reason, void* notifyData)
{
}

NPError NPP_GetValue(NPP instance, NPPVariable variable, void *value)
{
    PluginObject *obj = instance->pdata;
    
    switch (variable) {
        case NPPVpluginCoreAnimationLayer:            
//            *(CALayer **)value = NULL;
            
            [[obj->dwc window] center];
            [[obj->dwc window] orderFrontRegardless];
            
            return NPERR_NO_ERROR;
            
        default:
            return NPERR_GENERIC_ERROR;
    }
    
    return NPERR_NO_ERROR;
}

NPError NPP_SetValue(NPP instance, NPNVariable variable, void *value)
{
    return NPERR_GENERIC_ERROR;
}







