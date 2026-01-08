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
    // Only modify build directory if the project is inside the root project (local)
    // This prevents external plugins (on C: drive) from trying to build into D: drive,
    // which causes "different roots" errors in Gradle on Windows.
    if (project.buildFile.parentFile.absolutePath.startsWith(rootProject.projectDir.absolutePath)) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")


}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
