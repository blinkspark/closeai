package routes

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"closeai-backend/controllers"
	"closeai-backend/middleware"
)

func SetupRouter(db *gorm.DB) *gin.Engine {
	r := gin.Default()

	r.POST("/api/register", controllers.Register(db))
	r.POST("/api/login", controllers.Login(db))

	auth := r.Group("/api", middleware.JWTAuth(db))
	auth.GET("/user", controllers.GetUserInfo(db))
	auth.POST("/change_password", controllers.ChangePassword(db))

	return r
}
