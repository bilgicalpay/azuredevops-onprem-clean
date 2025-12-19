allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix root_detector namespace issue
// Apply namespace fix to root_detector package
subprojects {
    afterEvaluate {
        if (project.name == "root_detector") {
            try {
                val android = project.extensions.findByName("android")
                if (android != null) {
                    val androidExtension = android as? com.android.build.gradle.BaseExtension
                    if (androidExtension != null) {
                        try {
                            // Try to get namespace property
                            val namespaceProperty = androidExtension::class.java.getDeclaredMethod("getNamespace")
                            val currentNamespace = namespaceProperty.invoke(androidExtension) as? String
                            if (currentNamespace.isNullOrEmpty()) {
                                val setNamespaceMethod = androidExtension::class.java.getDeclaredMethod("setNamespace", String::class.java)
                                setNamespaceMethod.invoke(androidExtension, "space.wisnuwiry.root_detector")
                                println("✅ Added namespace 'space.wisnuwiry.root_detector' to root_detector")
                            }
                        } catch (e: Exception) {
                            // Fallback: try direct property access
                            try {
                                val namespaceField = androidExtension::class.java.getDeclaredField("namespace")
                                namespaceField.isAccessible = true
                                val currentNamespace = namespaceField.get(androidExtension) as? String
                                if (currentNamespace.isNullOrEmpty()) {
                                    namespaceField.set(androidExtension, "space.wisnuwiry.root_detector")
                                    println("✅ Added namespace to root_detector (field access)")
                                }
                            } catch (e2: Exception) {
                                println("⚠️  Could not set namespace for root_detector: ${e2.message}")
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                println("⚠️  Could not access android extension for root_detector: ${e.message}")
            }
        }
        
        // Set JVM target for all Kotlin tasks
        project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
        
        // Set Java compatibility for all projects
        project.tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
        
        // Fix package_info_plus JVM target compatibility
        if (project.name == "package_info_plus") {
            try {
                val android = project.extensions.findByName("android")
                if (android != null) {
                    val androidExtension = android as? com.android.build.gradle.BaseExtension
                    if (androidExtension != null) {
                        // Force Java 17 for package_info_plus
                        androidExtension.compileOptions {
                            sourceCompatibility = org.gradle.api.JavaVersion.VERSION_17
                            targetCompatibility = org.gradle.api.JavaVersion.VERSION_17
                        }
                    }
                }
            } catch (e: Exception) {
                println("⚠️  Could not set Java compatibility for package_info_plus: ${e.message}")
            }
        }
        
        // Fix root_detector JVM target compatibility
        if (project.name == "root_detector") {
            try {
                val android = project.extensions.findByName("android")
                if (android != null) {
                    val androidExtension = android as? com.android.build.gradle.BaseExtension
                    if (androidExtension != null) {
                        // Force Java 17 for root_detector
                        androidExtension.compileOptions {
                            sourceCompatibility = org.gradle.api.JavaVersion.VERSION_17
                            targetCompatibility = org.gradle.api.JavaVersion.VERSION_17
                        }
                    }
                }
            } catch (e: Exception) {
                println("⚠️  Could not set Java compatibility for root_detector: ${e.message}")
            }
        }
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
