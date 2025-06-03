// main.go
// 项目入口
package main

import (
	"log"

	"closeai-backend/config"
	"closeai-backend/models"
	"closeai-backend/routes"
)

func main() {
	db, err := config.InitDB()
	if err != nil {
		log.Fatal("数据库连接失败: ", err)
	}
	if err := models.MigrateUser(db); err != nil {
		log.Fatal("自动迁移失败: ", err)
	}
	r := routes.SetupRouter(db)
	r.Run(":8080")
}
