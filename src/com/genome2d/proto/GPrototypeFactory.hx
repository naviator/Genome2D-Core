package com.genome2d.proto;

import com.genome2d.globals.GParameters;
import Reflect;
import com.genome2d.debug.GDebug;

class GPrototypeFactory {
    static private var g2d_helper:GPrototypeHelper;
    static private var g2d_lookupsInitialized:Bool = false;
    static private var g2d_lookups:Map<String,Class<IGPrototypable>>;

    static public function getParameters():GParameters {
        // Somewhat of a hack since we use this part for code generation at macro time and even if it isn't executed macro prohibitons apply (platform dependant package import)
        #if !macro
        return Genome2D.getInstance().getParameters();
        #else
        return null;
        #end
    }

    static private function initializePrototypes():Void {
        if (g2d_lookups != null) return;
        g2d_lookups = new Map<String,Class<IGPrototypable>>();
		
		// For some reason when Haxe is compiled to JS it can't find classes generated during macro directly
		#if js
		var fields:Array<String> = untyped Type.getClassFields(com_genome2d_proto_GPrototypeHelper);
		#else
		var fields:Array<String> = Type.getClassFields(GPrototypeHelper);
		#end
		for (field in fields) {
			if (field.indexOf("g2d_") == 0) continue;
			#if js
			var cls:Class<IGPrototypable> = cast Type.resolveClass(Reflect.field(untyped com_genome2d_proto_GPrototypeHelper, field));
			#else
			var cls:Class<IGPrototypable> = cast Type.resolveClass(Reflect.field(GPrototypeHelper, field));
			#end
            if (cls != null) g2d_lookups.set(field, cls);
		}
		
    }

    static public function setPrototypeClass(p_prototypeName:String, p_class:Class<IGPrototypable>):Void {
        g2d_lookups.set(p_prototypeName, p_class);
    }

    static public function getPrototypeClass(p_prototypeName:String):Class<IGPrototypable> {
        return g2d_lookups.get(p_prototypeName);
    }

    static public function createInstance<T:IGPrototypable>(p_prototype:GPrototype, p_args:Array<Dynamic> = null):T {
        if (p_prototype.prototypeClass == null) {
            GDebug.error("Non existing prototype class "+p_prototype.prototypeName);
        }

        if (p_args == null) p_args = [];
        var proto:IGPrototypable = Type.createInstance(p_prototype.prototypeClass, p_args);
        if (proto == null) GDebug.error("Invalid prototype class " + p_prototype.prototypeName);
		
        proto.bindPrototype(p_prototype);

        return cast proto;
    }

    static public function createPrototypes(p_prototypes:Array<GPrototype>):Array<IGPrototypable> {
        var prototypeInstances:Array<IGPrototypable> = new Array<IGPrototypable>();
        for (prototype in p_prototypes) {
            prototypeInstances.push(createInstance(prototype));
        }
        return prototypeInstances;
    }
	
	static public function isValidProtototypeName(p_prototypeName:String):Bool {
		return g2d_lookups.exists(p_prototypeName);
	}

    static public function createEmptyPrototype(p_prototypeName:String):IGPrototypable {
        var prototypeClass:Class<IGPrototypable> = g2d_lookups.get(p_prototypeName);
        if (prototypeClass == null) {
            GDebug.error("Non existing prototype class "+p_prototypeName);
        }

        var proto:IGPrototypable = Type.createInstance(prototypeClass,[]);
        if (proto == null) GDebug.error("Invalid prototype class "+p_prototypeName);

        return proto;
    }

    // TODO: Refactor accessibility, macro reading
	static public function g2d_getPrototype(p_prototype:GPrototype, p_instance:IGPrototypable, p_prototypeName:String):GPrototype {
		if (p_prototype == null) p_prototype = new GPrototype();
		p_prototype.process(p_instance, p_prototypeName);

		return p_prototype;
	}

    // TODO: Refactor accessibility, macro reading
	static public function g2d_bindPrototype(p_instance:IGPrototypable, p_prototype:GPrototype, p_prototypeName:String):Void {
        if (p_prototype == null) GDebug.error("Null prototype");
		if (p_instance.g2d_prototypeStates == null) p_instance.g2d_prototypeStates = new GPrototypeStates();

		p_prototype.bind(p_instance, p_prototypeName);
    }
}
