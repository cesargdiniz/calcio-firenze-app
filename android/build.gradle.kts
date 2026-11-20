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

// O lint de release (lintVital) do Android Gradle Plugin quebra ao analisar
// plugins do Firebase (NoSuchMethodError no analisador de Kotlin). Ele só
// avisa sobre problemas; a compilação e os testes continuam valendo.
subprojects {
    tasks.matching { it.name.startsWith("lintVital") }.configureEach {
        enabled = false
    }
}
