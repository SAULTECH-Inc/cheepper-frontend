allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Force-exclude the Kotlin Multiplatform *-jvm artifacts from datastore 1.1.7
    // that are not present in the Gradle local cache, causing network failures.
    // The android variants (datastore-android, datastore-preferences-android) are cached
    // and are sufficient for an Android-only build.
    configurations.all {
        exclude(group = "androidx.datastore", module = "datastore-jvm")
        exclude(group = "androidx.datastore", module = "datastore-preferences-jvm")
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
