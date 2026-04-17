# 🛠️ Guía de Mantenimiento Técnico - Sports Quantum Stats

Esta guía está diseñada para que tú, como desarrollador, puedas gestionar las funciones críticas de la aplicación una vez que esté en la Play Store.

---

## 🚀 1. Cómo Forzar una Actualización (Force Update)

Si lanzas una nueva versión en la Google Play Store y quieres que todos tus usuarios la descarguen obligatoriamente (por un cambio crítico o nueva función), sigue estos pasos:

1.  **Sube la app a Play Store** y espera a que esté enviada/aprobada.
2.  **Abre el archivo** `version_config.json` en la raíz de tu proyecto.
3.  **Actualiza los campos**:
    *   `min_version`: Pon el número de versión nueva (ej: `"1.0.5"`).
    *   `store_url`: Asegúrate de que apunte a tu ficha de Play Store.
4.  **Sube el cambio a GitHub**:
    *   Abre la terminal en VS Code.
    *   Ejecuta:
    ```powershell
    git add version_config.json
    git commit -m "Force update to 1.0.5"
    git push origin main
    ```
5.  **Resultado**: En cuestión de segundos, cualquier usuario que abra la app con una versión menor a la 1.0.5 verá el diálogo neón de bloqueo.

---

## 📊 2. Gestión de Datos y Persistencia

La aplicación utiliza `SharedPreferences` para guardar los datos localmente. 

> [!WARNING]
> Si en el futuro decides cambiar drásticamente la estructura de la clase `Partido`, los partidos guardados viejos podrían dar error al cargar. Haz siempre pruebas antes de lanzar una actualización que cambie campos del modelo de datos.

### Limpieza de Memoria
Si necesitas limpiar todos los datos de prueba de tu teléfono o simulador:
*   Android: Ajustes > Aplicaciones > Sports Quantum Stats > Almacenamiento > **Borrar Datos**.
*   Esto borrará historial, plantillas y perfil de usuario.

---

## 🎨 3. Actualización de Iconos y Estética

*   **Logotipos**: Si decides cambiar el logo principal, reemplaza el archivo en `assets/logo.png`.
*   **Colores Globales**: Todos los colores neón están definidos en `lib/core/constants.dart`. Si quieres cambiar el tono del "Verde Quantum", modifícalo allí y se aplicará en toda la app.

---

## 📤 4. Exportación de Base de Datos

Cada partido genera un archivo CSV. Si un usuario tiene problemas:
1.  Dile que vaya a **Encuentros Guardados**.
2.  Abra el partido en cuestión.
3.  Use el botón de **Exportar (CSV)** para enviártelo por mail o WhatsApp. Esto te servirá para debuguear errores en las estadísticas.

---

> [!TIP]
> Mantén siempre una copia de seguridad local antes de hacer un `git push` de cambios grandes en la lógica de las estadísticas.
