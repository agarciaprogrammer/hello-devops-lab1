**Proyecto 1/6 – Hello DevOps**
===============================

**Objetivo general**
--------------------

Construir y desplegar una aplicación mínima pero completa, utilizando buenas prácticas básicas de DevOps: infraestructura como código, despliegue controlado y monitoreo. Este laboratorio establece un flujo funcional, reproducible y entendible, antes de avanzar hacia etapas más complejas.

**Stack de la aplicación**

### **Backend (API)**

*   Node.js + Express
    
*   Endpoint: /health
    

Respuesta esperada: {

  "status": "ok",

  "timestamp": "..."

}

### **Frontend**

*   Sitio estático (index.html)
    
*   Servido desde Amazon S3 (Static Website Hosting)
    

**Estructura del repositorio**

/api

  server.js

  package.json

/frontend

  index.html

/terraform

  main.tf

  variables.tf

  outputs.tf

/.github/workflows

  deploy.yml   (opcional)

**Infraestructura – Terraform + AWS**

**Servicios utilizados**
------------------------

### **1\. EC2 (API Server)**

*   AMI Amazon Linux 2023
    
*   Instancia t3.micro
    
*   Security Group:
    
    *   Puerto 80 abierto (HTTP)
        
    *   Puerto 22 restringido por IP
        
*   User-data:
    
    *   Instala Git + Node.js
        
    *   Clona el repositorio
        
    *   Instala dependencias
        
    *   Inicia la API
        

### **2\. S3 (Frontend)**

*   Bucket: hello-devops-lab1-frontend
    
*   Static Website Hosting habilitado
    
*   Archivo principal: index.html
    
*   Acceso público solo lectura
    

### **3\. IAM**

*   Rol para EC2 con permisos mínimos:
    
    *   logs:CreateLogStream
        
    *   logs:PutLogEvents
        
*   Instance Profile para asociarlo a EC2
    

### **4\. CloudWatch Logs**

*   Log Group: /aws/ec2/hello-devops-lab1-api
    
*   Recibe los logs generados por la API
    

**CI/CD – GitHub Actions**

Pipeline simple para este primer laboratorio.

### **Build/Test**

*   Instala dependencias
    
*   Corre linters o pruebas (opcional)
    

### **Deploy manual (workflow\_dispatch)**

Sube frontend/ al bucket S3:aws s3 sync frontend/ s3://hello-devops-lab1-frontend --delete

*   SSH a EC2 para actualizar la aplicación:
    
    *   Pull del repo
        
    *   Reinicio de la API
        

**Monitoreo y Seguridad**

### **Monitoreo**

*   Logs de la API en CloudWatch
    
*   Logs del arranque de instancia: /var/log/cloud-init-output.log
    

### **Seguridad**

*   Security Group restringido
    
*   IAM con permisos mínimos
    
*   Hosting S3 configurado solo para lectura pública
    
*   Infraestructura declarada completamente en Terraform
    

**Checklist final**

*   GET http:///health devuelve el JSON esperado
    
*   Bucket S3 sirve correctamente index.html
    
*   Logs de la API visibles en CloudWatch
    
*   GitHub Actions ejecuta el workflow manual y despliega
    
*   Terraform aplica sin cambios posteriores (infra reproducible)
