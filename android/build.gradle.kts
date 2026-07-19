allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Must register before evaluationDependsOn(":app"), otherwise afterEvaluate cannot run.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val compileSdkMethods =
            androidExt.javaClass.methods.filter {
                it.name in setOf("setCompileSdk", "setCompileSdkVersion", "compileSdkVersion") &&
                    it.parameterCount == 1
            }
        for (method in compileSdkMethods) {
            try {
                val paramType = method.parameterTypes[0]
                when {
                    paramType == Int::class.javaPrimitiveType || paramType == Integer::class.java ->
                        method.invoke(androidExt, 36)
                    paramType == String::class.java ->
                        method.invoke(androidExt, "36")
                    else -> continue
                }
                break
            } catch (_: Exception) {
                // Try next compatible setter.
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
