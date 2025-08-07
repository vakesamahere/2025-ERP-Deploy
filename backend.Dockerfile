# Java后端 Dockerfile - 多阶段构建
# 第一阶段：构建阶段
FROM maven:3.9.9-sapmachine-22 AS builder

# 设置工作目录
WORKDIR /app

# 配置Maven使用阿里云镜像源（提高下载速度）
RUN mkdir -p /root/.m2 && \
    echo '<?xml version="1.0" encoding="UTF-8"?>' > /root/.m2/settings.xml && \
    echo '<settings>' >> /root/.m2/settings.xml && \
    echo '  <mirrors>' >> /root/.m2/settings.xml && \
    echo '    <mirror>' >> /root/.m2/settings.xml && \
    echo '      <id>aliyun</id>' >> /root/.m2/settings.xml && \
    echo '      <name>Aliyun Maven Mirror</name>' >> /root/.m2/settings.xml && \
    echo '      <url>https://maven.aliyun.com/repository/central</url>' >> /root/.m2/settings.xml && \
    echo '      <mirrorOf>central</mirrorOf>' >> /root/.m2/settings.xml && \
    echo '    </mirror>' >> /root/.m2/settings.xml && \
    echo '  </mirrors>' >> /root/.m2/settings.xml && \
    echo '</settings>' >> /root/.m2/settings.xml

# 先复制依赖文件（pom.xml），利用Docker缓存
COPY backend/ERP/pom.xml ./

# 下载依赖（这一层会被缓存，除非pom.xml改变）
RUN mvn dependency:go-offline -B \
    -Dmaven.wagon.http.connectionTimeout=60000 \
    -Dmaven.wagon.http.readTimeout=60000 \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120

# 再复制源代码
COPY backend/ERP/src ./src

# 编译项目，跳过测试以加快构建速度
RUN mvn clean package -DskipTests -B \
    -Dmaven.wagon.http.connectionTimeout=60000 \
    -Dmaven.wagon.http.readTimeout=60000 \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120

# 第二阶段：运行阶段
FROM alpine/java:22-jre

# 设置工作目录
WORKDIR /app

# 从构建阶段复制JAR文件
COPY --from=builder /app/target/*.jar app.jar

# 暴露端口
EXPOSE 8080

# 健康检查（使用wget，Alpine自带）
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# 启动命令
CMD ["java", "-jar", "-Xmx512m", "-Xms256m", "app.jar"]
