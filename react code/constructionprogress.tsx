{/* Construction Progress - Only shown when under construction */}
        {residenceStatus === 'under-construction' && (
          <motion.div variants={item}>
            <Card className="border border-neutral-line-100 shadow-sm hover:shadow-lg transition-all duration-500 overflow-hidden bg-white">
              {/* Subtle aqua accent - fresh and light */}
              <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-bl from-aqua-green-100/30 to-transparent rounded-full blur-3xl"></div>
              <CardHeader className="pb-4 relative">
                <CardTitle className="flex items-center gap-2 text-neutral-ink-900">
                  {t('constructionProgress') || 'Construction Progress'}
                  <motion.div
                    animate={{ rotate: [0, 10, -10, 0] }}
                    transition={{ duration: 2, repeat: Infinity, repeatDelay: 3 }}
                  >
                    <Sparkles className="w-5 h-5 text-aqua-green-500" />
                  </motion.div>
                </CardTitle>
                <CardDescription className="text-neutral-ink-500">{t('yourHomeIsBeingBuilt') || 'Your new home is taking shape'}</CardDescription>
              </CardHeader>
              <CardContent className="px-6 pb-8">
                <ConstructionTimeline phases={constructionPhases} />
                
                {/* View More Details Button */}
                {permissions.canManageBuildings && (
                  <motion.div 
                    className="mt-6"
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.5 }}
                  >
                    <Button 
                      onClick={() => onNavigate('buildings')}
                      className="w-full bg-aqua-green-600 hover:bg-aqua-green-700 text-white shadow-sm hover:shadow-md transition-all"
                    >
                      <Building className="w-4 h-4 mr-2" />
                      {t('viewAllBuildings') || 'View All Buildings'}
                    </Button>
                  </motion.div>
                )}
              </CardContent>
            </Card>
          </motion.div>
        )}