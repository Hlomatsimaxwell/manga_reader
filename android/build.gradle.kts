import com.android.build.gradle.LibraryExtension

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

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Injects missing namespace into legacy packages like isar_flutter_libs
subprojects {
    plugins.withId("com.android.library") {
        configure<LibraryExtension> {
            if (namespace == null) {
                namespace = "dev.isar.${project.name.replace("-", "_")}"
            }
        }
    }
}